defmodule CyaneaWeb.ExploreLive do
  use CyaneaWeb, :live_view

  alias Cyanea.Repositories
  alias Cyanea.Search

  @impl true
  def mount(_params, _session, socket) do
    repositories = Repositories.list_public_repositories()

    {:ok,
     assign(socket,
       page_title: "Explore",
       repositories: repositories,
       search_query: "",
       active_tab: :repositories,
       user_results: []
     )}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    if query == "" do
      repositories = Repositories.list_public_repositories()
      {:noreply, assign(socket, repositories: repositories, search_query: "", user_results: [])}
    else
      {repositories, user_results} = perform_search(query)
      {:noreply, assign(socket, repositories: repositories, search_query: query, user_results: user_results)}
    end
  end

  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  defp perform_search(query) do
    repo_results =
      case Search.search_repositories(query, filter: "visibility = public") do
        {:ok, %{"hits" => hits}} when hits != [] ->
          # Load full records from DB by IDs
          ids = Enum.map(hits, & &1["id"])
          load_repositories_by_ids(ids)

        _ ->
          # Fallback to DB search
          db_fallback_search(query)
      end

    user_results =
      case Search.search_users(query) do
        {:ok, %{"hits" => hits}} -> hits
        _ -> []
      end

    {repo_results, user_results}
  end

  defp load_repositories_by_ids(ids) do
    import Ecto.Query

    from(r in Cyanea.Repositories.Repository,
      where: r.id in ^ids,
      where: r.visibility == "public",
      preload: [:owner, :organization]
    )
    |> Cyanea.Repo.all()
  end

  defp db_fallback_search(query) do
    repositories = Repositories.list_public_repositories()
    q = String.downcase(query)

    Enum.filter(repositories, fn repo ->
      String.contains?(String.downcase(repo.name), q) ||
        (repo.description && String.contains?(String.downcase(repo.description), q)) ||
        Enum.any?(repo.tags || [], &String.contains?(String.downcase(&1), q))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Explore
        <:subtitle>Discover public datasets, protocols, and research artifacts</:subtitle>
      </.header>

      <div class="mt-6">
        <.search_input value={@search_query} placeholder="Search repositories and users..." />
      </div>

      <%!-- Tabs --%>
      <div :if={@search_query != ""} class="mt-6">
        <.tabs>
          <:tab active={@active_tab == :repositories} click="switch-tab" value="repositories" count={length(@repositories)}>
            Repositories
          </:tab>
          <:tab active={@active_tab == :users} click="switch-tab" value="users" count={length(@user_results)}>
            Users
          </:tab>
        </.tabs>
      </div>

      <%!-- Repository results --%>
      <div :if={@active_tab == :repositories} class="mt-8 space-y-4">
        <div
          :for={repo <- @repositories}
          class="rounded-xl border border-slate-200 bg-white p-6 transition hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800 dark:hover:border-slate-600"
        >
          <div class="flex items-start justify-between">
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <.link
                  navigate={repo_path(repo)}
                  class="text-lg font-semibold text-primary hover:underline"
                >
                  <span class="text-slate-500"><%= repo_owner_name(repo) %>/</span><%= repo.name %>
                </.link>
                <.visibility_badge visibility={repo.visibility} />
              </div>
              <p :if={repo.description} class="mt-2 text-sm text-slate-600 dark:text-slate-400">
                <%= repo.description %>
              </p>
              <div class="mt-3 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                <.metadata_row :if={repo.license} icon="hero-scale">
                  <%= repo.license %>
                </.metadata_row>
                <.badge :for={tag <- repo.tags || []} color={:gray} size={:xs}><%= tag %></.badge>
                <.metadata_row icon="hero-star">
                  <%= repo.stars_count %>
                </.metadata_row>
              </div>
            </div>
          </div>
        </div>

        <.empty_state
          :if={@repositories == []}
          heading="No repositories found."
        />
      </div>

      <%!-- User results --%>
      <div :if={@active_tab == :users && @search_query != ""} class="mt-8 space-y-4">
        <div
          :for={user <- @user_results}
          class="flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800"
        >
          <.avatar name={user["username"] || ""} size={:md} />
          <div>
            <.link navigate={~p"/#{user["username"]}"} class="font-semibold text-primary hover:underline">
              <%= user["name"] || user["username"] %>
            </.link>
            <p class="text-xs text-slate-500">@<%= user["username"] %></p>
            <p :if={user["affiliation"] && user["affiliation"] != ""} class="text-xs text-slate-400"><%= user["affiliation"] %></p>
          </div>
        </div>

        <.empty_state :if={@user_results == []} heading="No users found." />
      </div>
    </div>
    """
  end

  defp repo_path(repo) do
    cond do
      repo.owner -> ~p"/#{repo.owner.username}/#{repo.slug}"
      repo.organization -> ~p"/#{repo.organization.slug}/#{repo.slug}"
      true -> "#"
    end
  end

  defp repo_owner_name(repo) do
    cond do
      repo.owner -> repo.owner.username
      repo.organization -> repo.organization.slug
      true -> "unknown"
    end
  end
end

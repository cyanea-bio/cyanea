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
        <form phx-change="search" phx-submit="search">
          <div class="relative">
            <.icon name="hero-magnifying-glass" class="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search repositories and users..."
              phx-debounce="300"
              class="block w-full rounded-lg border-slate-300 pl-10 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm dark:border-slate-600 dark:bg-slate-800"
            />
          </div>
        </form>
      </div>

      <%!-- Tabs --%>
      <div :if={@search_query != ""} class="mt-6 flex gap-4 border-b border-slate-200 dark:border-slate-700">
        <button
          phx-click="switch-tab"
          phx-value-tab="repositories"
          class={[
            "border-b-2 px-1 pb-3 text-sm font-medium",
            if(@active_tab == :repositories,
              do: "border-primary-500 text-primary",
              else: "border-transparent text-slate-500 hover:text-slate-700"
            )
          ]}
        >
          Repositories (<%= length(@repositories) %>)
        </button>
        <button
          phx-click="switch-tab"
          phx-value-tab="users"
          class={[
            "border-b-2 px-1 pb-3 text-sm font-medium",
            if(@active_tab == :users,
              do: "border-primary-500 text-primary",
              else: "border-transparent text-slate-500 hover:text-slate-700"
            )
          ]}
        >
          Users (<%= length(@user_results) %>)
        </button>
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
                <span class={[
                  "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
                  if(repo.visibility == "public",
                    do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
                    else: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
                  )
                ]}>
                  <%= repo.visibility %>
                </span>
              </div>
              <p :if={repo.description} class="mt-2 text-sm text-slate-600 dark:text-slate-400">
                <%= repo.description %>
              </p>
              <div class="mt-3 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                <span :if={repo.license} class="flex items-center gap-1">
                  <.icon name="hero-scale" class="h-3.5 w-3.5" />
                  <%= repo.license %>
                </span>
                <span :for={tag <- repo.tags || []} class="rounded-full bg-slate-100 px-2 py-0.5 dark:bg-slate-700">
                  <%= tag %>
                </span>
                <span class="flex items-center gap-1">
                  <.icon name="hero-star" class="h-3.5 w-3.5" />
                  <%= repo.stars_count %>
                </span>
              </div>
            </div>
          </div>
        </div>

        <p
          :if={@repositories == []}
          class="py-12 text-center text-slate-500 dark:text-slate-400"
        >
          No repositories found.
        </p>
      </div>

      <%!-- User results --%>
      <div :if={@active_tab == :users && @search_query != ""} class="mt-8 space-y-4">
        <div
          :for={user <- @user_results}
          class="flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800"
        >
          <img
            src={"https://api.dicebear.com/7.x/initials/svg?seed=#{user["username"]}"}
            alt={user["username"]}
            class="h-10 w-10 rounded-full"
          />
          <div>
            <.link navigate={~p"/#{user["username"]}"} class="font-semibold text-primary hover:underline">
              <%= user["name"] || user["username"] %>
            </.link>
            <p class="text-xs text-slate-500">@<%= user["username"] %></p>
            <p :if={user["affiliation"] && user["affiliation"] != ""} class="text-xs text-slate-400"><%= user["affiliation"] %></p>
          </div>
        </div>

        <p :if={@user_results == []} class="py-12 text-center text-slate-500 dark:text-slate-400">
          No users found.
        </p>
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

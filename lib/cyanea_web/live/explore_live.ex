defmodule CyaneaWeb.ExploreLive do
  use CyaneaWeb, :live_view

  import CyaneaWeb.ActivityEventComponent

  alias Cyanea.Activity
  alias Cyanea.Search
  alias Cyanea.Spaces

  @impl true
  def mount(_params, _session, socket) do
    spaces = Spaces.list_public_spaces()
    trending = Spaces.list_trending_spaces(limit: 5)

    {:ok,
     assign(socket,
       page_title: "Explore",
       spaces: spaces,
       trending: trending,
       search_query: "",
       active_tab: :spaces,
       sort: "recently_updated",
       user_results: [],
       activity_events: [],
       ontology_filter: ""
     )}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    if query == "" do
      spaces = load_spaces(socket.assigns.sort)
      {:noreply, assign(socket, spaces: spaces, search_query: "", user_results: [])}
    else
      {spaces, user_results} = perform_search(query)
      {:noreply, assign(socket, spaces: spaces, search_query: query, user_results: user_results)}
    end
  end

  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)

    socket =
      if tab == :activity && socket.assigns.activity_events == [] do
        events = Activity.list_global_feed(limit: 20)
        assign(socket, activity_events: events)
      else
        socket
      end

    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("sort", %{"sort" => sort}, socket) do
    spaces = load_spaces(sort)
    {:noreply, assign(socket, spaces: spaces, sort: sort)}
  end

  def handle_event("filter-ontology", %{"ontology" => term}, socket) do
    if String.trim(term) == "" do
      spaces = load_spaces(socket.assigns.sort)
      {:noreply, assign(socket, spaces: spaces, ontology_filter: "")}
    else
      spaces = filter_by_ontology(term)
      {:noreply, assign(socket, spaces: spaces, ontology_filter: term)}
    end
  end

  defp load_spaces("most_starred"), do: Spaces.list_trending_spaces(limit: 50)
  defp load_spaces(_), do: Spaces.list_public_spaces()

  defp perform_search(query) do
    space_results =
      case Search.search_spaces(query, filter: "visibility = public") do
        {:ok, %{"hits" => hits}} when hits != [] ->
          ids = Enum.map(hits, & &1["id"])
          load_spaces_by_ids(ids)

        _ ->
          db_fallback_search(query)
      end

    user_results =
      case Search.search_users(query) do
        {:ok, %{"hits" => hits}} -> hits
        _ -> []
      end

    {space_results, user_results}
  end

  defp load_spaces_by_ids(ids) do
    import Ecto.Query

    from(s in Cyanea.Spaces.Space,
      where: s.id in ^ids,
      where: s.visibility == "public"
    )
    |> Cyanea.Repo.all()
  end

  defp filter_by_ontology(term) do
    term_lower = String.downcase(term)

    Spaces.list_public_spaces()
    |> Enum.filter(fn space ->
      Enum.any?(space.ontology_terms || [], fn t ->
        id = (t["id"] || "") |> String.downcase()
        label = (t["label"] || "") |> String.downcase()
        String.contains?(id, term_lower) or String.contains?(label, term_lower)
      end)
    end)
  end

  defp db_fallback_search(query) do
    spaces = Spaces.list_public_spaces()
    q = String.downcase(query)

    Enum.filter(spaces, fn space ->
      String.contains?(String.downcase(space.name), q) ||
        (space.description && String.contains?(String.downcase(space.description), q)) ||
        Enum.any?(space.tags || [], &String.contains?(String.downcase(&1), q))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Explore
        <:subtitle>Discover public datasets, protocols, and research spaces</:subtitle>
      </.header>

      <div class="mt-6">
        <.search_input value={@search_query} placeholder="Search spaces and users..." />
      </div>

      <%!-- Tabs --%>
      <div class="mt-6">
        <.tabs>
          <:tab active={@active_tab == :spaces} click="switch-tab" value="spaces" count={length(@spaces)}>
            Spaces
          </:tab>
          <:tab :if={@search_query != ""} active={@active_tab == :users} click="switch-tab" value="users" count={length(@user_results)}>
            Users
          </:tab>
          <:tab active={@active_tab == :activity} click="switch-tab" value="activity">
            Activity
          </:tab>
        </.tabs>
      </div>

      <%!-- Ontology filter --%>
      <div :if={@active_tab == :spaces} class="mt-4">
        <form phx-change="filter-ontology" class="flex items-center gap-2">
          <label class="text-sm text-slate-500">Ontology filter:</label>
          <input
            type="text"
            name="ontology"
            value={@ontology_filter}
            placeholder="e.g. GO:0008150, Homo sapiens..."
            phx-debounce="300"
            class="w-64 rounded-lg border border-slate-200 px-3 py-1.5 text-sm dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200"
          />
          <button
            :if={@ontology_filter != ""}
            type="button"
            phx-click="filter-ontology"
            phx-value-ontology=""
            class="text-xs text-slate-500 hover:text-slate-700"
          >
            Clear
          </button>
        </form>
      </div>

      <%!-- Sort options (only for spaces tab when not searching) --%>
      <div :if={@active_tab == :spaces && @search_query == ""} class="mt-4 flex items-center gap-2">
        <span class="text-sm text-slate-500">Sort:</span>
        <button
          :for={{label, value} <- [{"Recently updated", "recently_updated"}, {"Most starred", "most_starred"}]}
          phx-click="sort"
          phx-value-sort={value}
          class={[
            "rounded-lg px-3 py-1 text-sm",
            if(@sort == value,
              do: "bg-primary text-white",
              else: "bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300"
            )
          ]}
        >
          <%= label %>
        </button>
      </div>

      <%!-- Trending section --%>
      <div :if={@active_tab == :spaces && @search_query == "" && @trending != []} class="mt-6">
        <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Trending</h3>
        <div class="mt-3 flex flex-wrap gap-2">
          <.link
            :for={space <- @trending}
            navigate={space_path(space)}
            class="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
          >
            <.icon name="hero-star" class="h-3.5 w-3.5 text-yellow-500" />
            <span class="text-slate-500"><%= space_owner_name(space) %>/</span><%= space.name %>
            <span class="text-xs text-slate-400"><%= space.star_count %></span>
          </.link>
        </div>
      </div>

      <%!-- Space results --%>
      <div :if={@active_tab == :spaces} class="mt-8 space-y-4">
        <div
          :for={space <- @spaces}
          class="rounded-xl border border-slate-200 bg-white p-6 transition hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800 dark:hover:border-slate-600"
        >
          <div class="flex items-start justify-between">
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <.link
                  navigate={space_path(space)}
                  class="text-lg font-semibold text-primary hover:underline"
                >
                  <span class="text-slate-500"><%= space_owner_name(space) %>/</span><%= space.name %>
                </.link>
                <.visibility_badge visibility={space.visibility} />
              </div>
              <p :if={space.description} class="mt-2 text-sm text-slate-600 dark:text-slate-400">
                <%= space.description %>
              </p>
              <div class="mt-3 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                <.metadata_row :if={space.license} icon="hero-scale">
                  <%= space.license %>
                </.metadata_row>
                <.badge :for={tag <- space.tags || []} color={:gray} size={:xs}><%= tag %></.badge>
                <.metadata_row icon="hero-star">
                  <%= space.star_count %>
                </.metadata_row>
                <.metadata_row :if={space.fork_count > 0} icon="hero-arrow-path-rounded-square">
                  <%= space.fork_count %>
                </.metadata_row>
              </div>
            </div>
          </div>
        </div>

        <.empty_state
          :if={@spaces == []}
          heading="No spaces found."
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

      <%!-- Activity tab --%>
      <div :if={@active_tab == :activity} class="mt-8">
        <.card>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Global activity</h3>
          <div :if={@activity_events != []} class="mt-3 divide-y divide-slate-100 dark:divide-slate-700">
            <.activity_event :for={event <- @activity_events} event={event} />
          </div>
          <p :if={@activity_events == []} class="mt-3 text-sm text-slate-500">
            No activity yet.
          </p>
        </.card>
      </div>
    </div>
    """
  end

  defp space_path(space) do
    owner = space_owner_name(space)
    ~p"/#{owner}/#{space.slug}"
  end

  defp space_owner_name(space) do
    Cyanea.Spaces.owner_display(space)
  end
end

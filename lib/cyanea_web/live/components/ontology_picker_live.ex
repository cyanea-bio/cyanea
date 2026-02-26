defmodule CyaneaWeb.Components.OntologyPickerLive do
  @moduledoc """
  LiveComponent for searching and selecting ontology terms.

  Provides an autocomplete search input with debounced queries to OLS4
  and NCBI Taxonomy APIs. Selected terms are displayed as removable badges.
  """
  use CyaneaWeb, :live_component

  alias Cyanea.Ontologies

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       search_query: "",
       search_results: [],
       active_source: "go",
       loading: false
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected_terms, fn -> [] end)
     |> assign_new(:ontology_filter, fn -> nil end)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    if String.trim(query) == "" do
      {:noreply, assign(socket, search_query: "", search_results: [])}
    else
      source = socket.assigns.active_source
      results = do_search(query, source)
      {:noreply, assign(socket, search_query: query, search_results: results)}
    end
  end

  def handle_event("switch-source", %{"source" => source}, socket) do
    socket = assign(socket, active_source: source, search_results: [])

    # Re-search if there's a query
    socket =
      if socket.assigns.search_query != "" do
        results = do_search(socket.assigns.search_query, source)
        assign(socket, search_results: results)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("select-term", %{"id" => id, "label" => label, "source" => source, "uri" => uri}, socket) do
    term = %{"id" => id, "label" => label, "source" => source, "uri" => uri}

    # Avoid duplicates
    already_selected = Enum.any?(socket.assigns.selected_terms, &(&1["id"] == id))

    if already_selected do
      {:noreply, socket}
    else
      new_terms = socket.assigns.selected_terms ++ [term]
      send(self(), {__MODULE__, :terms_updated, socket.assigns.id, new_terms})
      {:noreply, assign(socket, selected_terms: new_terms, search_results: [], search_query: "")}
    end
  end

  def handle_event("remove-term", %{"id" => id}, socket) do
    new_terms = Enum.reject(socket.assigns.selected_terms, &(&1["id"] == id))
    send(self(), {__MODULE__, :terms_updated, socket.assigns.id, new_terms})
    {:noreply, assign(socket, selected_terms: new_terms)}
  end

  @impl true
  def render(assigns) do
    sources = Ontologies.ontology_sources()
    assigns = assign(assigns, sources: sources)

    ~H"""
    <div class="space-y-3">
      <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
        Ontology terms
      </label>

      <%!-- Source selector --%>
      <div class="flex flex-wrap gap-1">
        <button
          :for={source <- @sources}
          type="button"
          phx-click="switch-source"
          phx-value-source={source.id}
          phx-target={@myself}
          class={[
            "rounded-md px-2.5 py-1 text-xs font-medium transition",
            if(@active_source == source.id,
              do: "bg-primary text-white",
              else: "bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300"
            )
          ]}
        >
          <%= source.name %>
        </button>
      </div>

      <%!-- Search input --%>
      <div class="relative">
        <input
          type="text"
          value={@search_query}
          phx-keyup="search"
          phx-debounce="300"
          phx-target={@myself}
          placeholder={"Search #{active_source_name(@active_source, @sources)}..."}
          class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200"
          autocomplete="off"
        />

        <%!-- Search results dropdown --%>
        <div
          :if={@search_results != []}
          class="absolute z-10 mt-1 max-h-60 w-full overflow-y-auto rounded-lg border border-slate-200 bg-white shadow-lg dark:border-slate-600 dark:bg-slate-800"
        >
          <button
            :for={result <- @search_results}
            type="button"
            phx-click="select-term"
            phx-value-id={result.id}
            phx-value-label={result.label}
            phx-value-source={result.source}
            phx-value-uri={result.uri}
            phx-target={@myself}
            class="flex w-full items-start gap-2 px-3 py-2 text-left text-sm hover:bg-slate-50 dark:hover:bg-slate-700"
          >
            <span class="shrink-0 rounded bg-slate-100 px-1.5 py-0.5 text-xs font-mono text-slate-600 dark:bg-slate-700 dark:text-slate-400">
              <%= result.id %>
            </span>
            <span class="text-slate-900 dark:text-white"><%= result.label %></span>
          </button>
        </div>
      </div>

      <%!-- Selected terms --%>
      <div :if={@selected_terms != []} class="flex flex-wrap gap-2">
        <span
          :for={term <- @selected_terms}
          class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary dark:bg-primary/20"
        >
          <span class="font-mono text-[10px] opacity-70"><%= term["id"] %></span>
          <%= term["label"] %>
          <button
            type="button"
            phx-click="remove-term"
            phx-value-id={term["id"]}
            phx-target={@myself}
            class="ml-0.5 text-primary/60 hover:text-primary"
          >
            &times;
          </button>
        </span>
      </div>

      <p :if={@selected_terms == []} class="text-xs text-slate-500">
        Search and add ontology terms to improve discoverability.
      </p>
    </div>
    """
  end

  # -- Private --

  defp do_search(query, "ncbitaxon") do
    case Ontologies.search_organisms(query) do
      {:ok, organisms} ->
        Enum.map(organisms, fn org ->
          label =
            if org.common_name && org.common_name != "" do
              "#{org.scientific_name} (#{org.common_name})"
            else
              org.scientific_name
            end

          %{
            id: "NCBITaxon:#{org.taxon_id}",
            label: label,
            source: "ncbitaxon",
            uri: "https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=#{org.taxon_id}"
          }
        end)

      {:error, _} ->
        []
    end
  end

  defp do_search(query, source) do
    case Ontologies.search_terms(query, ontology: source, limit: 10) do
      {:ok, terms} -> terms
      {:error, _} -> []
    end
  end

  defp active_source_name(id, sources) do
    case Enum.find(sources, &(&1.id == id)) do
      nil -> id
      source -> source.name
    end
  end
end

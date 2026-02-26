defmodule CyaneaWeb.CitationComponents do
  @moduledoc """
  Components for citations, FAIR score badges, contributors, and lineage.
  """
  use Phoenix.Component

  import CyaneaWeb.CoreComponents
  import CyaneaWeb.UIComponents
  import CyaneaWeb.DataComponents

  use Phoenix.VerifiedRoutes,
    endpoint: CyaneaWeb.Endpoint,
    router: CyaneaWeb.Router,
    statics: CyaneaWeb.static_paths()

  attr :id, :string, default: "cite-modal"

  def cite_button(assigns) do
    ~H"""
    <button
      phx-click={show_modal(@id)}
      class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
    >
      <.icon name="hero-document-text" class="h-4 w-4" />
      Cite
    </button>
    """
  end

  attr :id, :string, default: "cite-modal"
  attr :bibtex, :string, required: true
  attr :ris, :string, required: true
  attr :apa, :string, required: true

  def citation_modal(assigns) do
    ~H"""
    <.modal id={@id}>
      <div class="space-y-4">
        <h2 class="text-lg font-semibold text-slate-900 dark:text-white">Cite this space</h2>

        <%!-- APA --%>
        <div>
          <div class="mb-1 flex items-center justify-between">
            <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">APA</h3>
            <.copy_button id="copy-apa" text={@apa} />
          </div>
          <div class="rounded-lg bg-slate-50 p-3 text-sm text-slate-700 dark:bg-slate-800 dark:text-slate-300">
            <%= @apa %>
          </div>
        </div>

        <%!-- BibTeX --%>
        <div>
          <div class="mb-1 flex items-center justify-between">
            <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">BibTeX</h3>
            <.copy_button id="copy-bibtex" text={@bibtex} />
          </div>
          <pre class="overflow-x-auto rounded-lg bg-slate-50 p-3 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-300"><code><%= @bibtex %></code></pre>
        </div>

        <%!-- RIS --%>
        <div>
          <div class="mb-1 flex items-center justify-between">
            <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">RIS</h3>
            <.copy_button id="copy-ris" text={@ris} />
          </div>
          <pre class="overflow-x-auto rounded-lg bg-slate-50 p-3 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-300"><code><%= @ris %></code></pre>
        </div>
      </div>
    </.modal>
    """
  end

  attr :contributors, :list, required: true

  def contributors_list(assigns) do
    ~H"""
    <div :if={@contributors != []}>
      <h3 class="mb-3 text-sm font-semibold text-slate-900 dark:text-white">Contributors</h3>
      <div class="space-y-2">
        <div
          :for={contrib <- @contributors}
          class="flex items-center gap-3"
        >
          <.avatar name={contrib.username || ""} size={:sm} />
          <div>
            <.link navigate={~p"/#{contrib.username}"} class="text-sm font-medium text-primary hover:underline">
              <%= contrib.name || contrib.username %>
            </.link>
            <a
              :if={contrib[:orcid_id]}
              href={"https://orcid.org/#{contrib.orcid_id}"}
              target="_blank"
              class="ml-1 text-xs text-emerald-600 hover:text-emerald-700"
              title="ORCID"
            >
              ORCID
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :score, :map, required: true

  def fair_badge(assigns) do
    color =
      cond do
        assigns.score.total >= 70 -> :success
        assigns.score.total >= 40 -> :warning
        true -> :error
      end

    assigns = assign(assigns, color: color)

    ~H"""
    <div class="flex items-center gap-1.5">
      <.badge color={@color}>FAIR: <%= @score.total %>/100</.badge>
    </div>
    """
  end

  attr :score, :map, required: true

  def fair_breakdown(assigns) do
    ~H"""
    <div class="space-y-2">
      <h4 class="text-xs font-medium text-slate-600 dark:text-slate-400">FAIR Score Breakdown</h4>
      <.fair_bar label="Findable" value={@score.findable} max={25} />
      <.fair_bar label="Accessible" value={@score.accessible} max={25} />
      <.fair_bar label="Interoperable" value={@score.interoperable} max={20} />
      <.fair_bar label="Reusable" value={@score.reusable} max={30} />
    </div>
    """
  end

  defp fair_bar(assigns) do
    percent = if assigns.max > 0, do: min(assigns.value / assigns.max * 100, 100), else: 0
    assigns = assign(assigns, percent: percent)

    ~H"""
    <div>
      <div class="flex items-center justify-between text-xs">
        <span class="text-slate-600 dark:text-slate-400"><%= @label %></span>
        <span class="font-medium text-slate-700 dark:text-slate-300"><%= @value %>/<%= @max %></span>
      </div>
      <div class="mt-0.5 h-1.5 w-full rounded-full bg-slate-200 dark:bg-slate-700">
        <div
          class="h-full rounded-full bg-primary transition-all"
          style={"width: #{@percent}%"}
        />
      </div>
    </div>
    """
  end

  attr :ancestors, :list, required: true
  attr :descendants, :list, required: true
  attr :current_name, :string, required: true

  def lineage_tree(assigns) do
    ~H"""
    <div :if={@ancestors != [] or @descendants != []}>
      <h3 class="mb-3 text-sm font-semibold text-slate-900 dark:text-white">Lineage</h3>
      <div class="space-y-1 text-sm">
        <%!-- Ancestors (oldest first) --%>
        <div :for={ancestor <- Enum.reverse(@ancestors)} class="flex items-center gap-2">
          <span class="text-slate-400">&uarr;</span>
          <.link
            navigate={~p"/#{ancestor.owner_name}/#{ancestor.slug}"}
            class="text-primary hover:underline"
          >
            <%= ancestor.owner_name %>/<%= ancestor.name %>
          </.link>
        </div>

        <%!-- Current --%>
        <div class="flex items-center gap-2 font-medium text-slate-900 dark:text-white">
          <span class="text-slate-400">&bull;</span>
          <%= @current_name %>
          <.badge color={:primary} size={:xs}>current</.badge>
        </div>

        <%!-- Descendants --%>
        <div :for={desc <- @descendants} class="flex items-center gap-2">
          <span class="text-slate-400">&darr;</span>
          <.link
            navigate={~p"/#{desc.owner_name}/#{desc.slug}"}
            class="text-primary hover:underline"
          >
            <%= desc.owner_name %>/<%= desc.name %>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end

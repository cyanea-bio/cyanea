defmodule CyaneaWeb.NotebookLive.Show do
  use CyaneaWeb, :live_view

  alias Cyanea.Notebooks
  alias CyaneaWeb.ContentHelpers
  alias CyaneaWeb.Markdown

  @impl true
  def mount(%{"notebook_slug" => notebook_slug} = params, _session, socket) do
    case ContentHelpers.mount_space(socket, params) do
      {:ok, socket} ->
        space = socket.assigns.space
        notebook = Notebooks.get_notebook_by_slug(space.id, notebook_slug)

        if notebook do
          {:ok,
           socket
           |> assign(
             page_title: notebook.title,
             notebook: notebook,
             cells: Notebooks.get_cells(notebook),
             editing_cell_id: nil,
             save_status: :saved,
             cell_outputs: %{},
             running_cells: MapSet.new()
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "Notebook not found.")
           |> redirect(to: ~p"/#{socket.assigns.owner_name}/#{space.slug}")}
        end

      {:error, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("add-cell", %{"type" => type} = params, socket) do
    position = if params["position"], do: String.to_integer(params["position"]), else: nil

    case Notebooks.add_cell(socket.assigns.notebook, type, position) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> assign(notebook: notebook, cells: Notebooks.get_cells(notebook))
         |> assign(save_status: :saved)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add cell.")}
    end
  end

  def handle_event("delete-cell", %{"cell-id" => cell_id}, socket) do
    case Notebooks.remove_cell(socket.assigns.notebook, cell_id) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> assign(notebook: notebook, cells: Notebooks.get_cells(notebook))
         |> assign(editing_cell_id: nil, save_status: :saved)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete cell.")}
    end
  end

  def handle_event("move-cell", %{"cell-id" => cell_id, "direction" => direction}, socket) do
    direction = String.to_existing_atom(direction)

    case Notebooks.move_cell(socket.assigns.notebook, cell_id, direction) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> assign(notebook: notebook, cells: Notebooks.get_cells(notebook))
         |> assign(save_status: :saved)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move cell.")}
    end
  end

  def handle_event("edit-cell", %{"cell-id" => cell_id}, socket) do
    {:noreply, assign(socket, editing_cell_id: cell_id)}
  end

  def handle_event("finish-edit", _params, socket) do
    {:noreply, assign(socket, editing_cell_id: nil)}
  end

  def handle_event("update-cell", %{"cell-id" => cell_id, "source" => source}, socket) do
    case Notebooks.update_cell(socket.assigns.notebook, cell_id, %{"source" => source}) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> assign(notebook: notebook, cells: Notebooks.get_cells(notebook))
         |> assign(save_status: :saved)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update cell.")}
    end
  end

  def handle_event(
        "update-cell-language",
        %{"cell-id" => cell_id, "language" => language},
        socket
      ) do
    case Notebooks.update_cell(socket.assigns.notebook, cell_id, %{"language" => language}) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> assign(notebook: notebook, cells: Notebooks.get_cells(notebook))
         |> assign(save_status: :saved)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("run-cell", %{"cell-id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1["id"] == cell_id))

    if cell && Notebooks.executable_cell?(cell) do
      {:noreply,
       socket
       |> update(:running_cells, &MapSet.put(&1, cell_id))
       |> push_event("execute-cell", %{cell_id: cell_id, source: cell["source"] || ""})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("run-all", _params, socket) do
    executable_cells =
      socket.assigns.cells
      |> Enum.filter(&Notebooks.executable_cell?/1)
      |> Enum.map(&%{id: &1["id"], source: &1["source"] || ""})

    running_ids = executable_cells |> Enum.map(& &1.id) |> MapSet.new()

    {:noreply,
     socket
     |> assign(running_cells: running_ids)
     |> push_event("execute-all", %{cells: executable_cells})}
  end

  def handle_event("clear-outputs", _params, socket) do
    {:noreply, assign(socket, cell_outputs: %{}, running_cells: MapSet.new())}
  end

  def handle_event("cell-result", %{"cell-id" => cell_id, "output" => output}, socket) do
    {:noreply,
     socket
     |> update(:cell_outputs, &Map.put(&1, cell_id, output))
     |> update(:running_cells, &MapSet.delete(&1, cell_id))}
  end

  def handle_event("auto-save", _params, socket) do
    {:noreply,
     socket
     |> push_event("auto-save-done", %{})
     |> assign(save_status: :saved)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Breadcrumb --%>
      <div class="flex items-center justify-between">
        <.breadcrumb>
          <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
          <:crumb navigate={~p"/#{@owner_name}/#{@space.slug}"}><%= @space.name %></:crumb>
          <:crumb><%= @notebook.title %></:crumb>
        </.breadcrumb>
        <div class="flex items-center gap-3">
          <.status_indicator
            :if={@is_owner}
            status={save_status_to_indicator(@save_status)}
            label={save_status_label(@save_status)}
          />
        </div>
      </div>

      <%!-- Notebook toolbar --%>
      <div :if={@is_owner && has_executable_cells?(@cells)} class="mt-4 flex items-center gap-2">
        <button
          phx-click="run-all"
          class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-3 py-1.5 text-sm font-medium text-white hover:bg-primary/90 transition"
        >
          <.icon name="hero-play" class="h-4 w-4" /> Run All
        </button>
        <button
          :if={@cell_outputs != %{}}
          phx-click="clear-outputs"
          class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
        >
          <.icon name="hero-x-mark" class="h-4 w-4" /> Clear Outputs
        </button>
      </div>

      <%!-- Notebook content --%>
      <div class="mt-6 space-y-4" id="notebook-cells" phx-hook="NotebookExecutor">
        <%= if @cells == [] and @is_owner do %>
          <div class="flex justify-center gap-2">
            <button
              phx-click="add-cell"
              phx-value-type="markdown"
              class="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-2 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Markdown
            </button>
            <button
              phx-click="add-cell"
              phx-value-type="code"
              class="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-2 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Code
            </button>
          </div>
        <% end %>

        <div :for={cell <- @cells}>
          <%= if @is_owner do %>
            <.cell_editor
              cell={cell}
              editing={@editing_cell_id == cell["id"]}
              owner_name={@owner_name}
              cell_output={@cell_outputs[cell["id"]]}
              running={MapSet.member?(@running_cells, cell["id"])}
            />
          <% else %>
            <.cell_viewer cell={cell} />
          <% end %>

          <%!-- Add cell button between cells (owner only) --%>
          <div :if={@is_owner} class="flex justify-center gap-2 py-1 opacity-0 hover:opacity-100 transition-opacity">
            <button
              phx-click="add-cell"
              phx-value-type="markdown"
              phx-value-position={cell["position"] + 1}
              class="inline-flex items-center gap-1 rounded border border-slate-200 px-2 py-1 text-xs hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              + Markdown
            </button>
            <button
              phx-click="add-cell"
              phx-value-type="code"
              phx-value-position={cell["position"] + 1}
              class="inline-flex items-center gap-1 rounded border border-slate-200 px-2 py-1 text-xs hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              + Code
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # -- Cell Editor (owner view) --

  defp cell_editor(%{cell: %{"type" => "markdown"}} = assigns) do
    ~H"""
    <.card class="group relative">
      <div class="absolute right-2 top-2 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        <.cell_toolbar cell_id={@cell["id"]} />
      </div>

      <%= if @editing do %>
        <div class="space-y-2">
          <textarea
            phx-blur="update-cell"
            phx-value-cell-id={@cell["id"]}
            name="source"
            rows={max(3, length(String.split(@cell["source"] || "", "\n")))}
            class="w-full rounded-lg border border-slate-200 bg-slate-50 p-4 font-mono text-sm dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200"
          ><%= @cell["source"] %></textarea>
          <button
            phx-click="finish-edit"
            class="text-xs text-primary hover:text-primary/80"
          >
            Done editing
          </button>
        </div>
      <% else %>
        <div
          phx-click="edit-cell"
          phx-value-cell-id={@cell["id"]}
          class="prose prose-sm max-w-none cursor-pointer dark:prose-invert"
        >
          <%= if @cell["source"] && @cell["source"] != "" do %>
            <%= Markdown.render(@cell["source"]) %>
          <% else %>
            <p class="text-slate-400 italic">Click to edit markdown...</p>
          <% end %>
        </div>
      <% end %>
    </.card>
    """
  end

  defp cell_editor(%{cell: %{"type" => "code"}} = assigns) do
    assigns = assign(assigns, :is_cyanea, assigns.cell["language"] == "cyanea")

    ~H"""
    <.card class="group relative" padding="p-0">
      <%!-- Code cell header --%>
      <div class="flex items-center justify-between border-b border-slate-200 bg-slate-50 px-4 py-1.5 dark:border-slate-700 dark:bg-slate-900/50">
        <div class="flex items-center gap-2">
          <span class="text-xs font-medium text-slate-500">
            <%= String.upcase(@cell["language"] || "code") %>
          </span>
          <span
            :if={!@is_cyanea}
            class="rounded-full bg-slate-200 px-2 py-0.5 text-[10px] font-medium text-slate-500 dark:bg-slate-700 dark:text-slate-400"
          >
            Server only
          </span>
        </div>
        <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <select
            phx-change="update-cell-language"
            phx-value-cell-id={@cell["id"]}
            name="language"
            class="rounded border border-slate-200 bg-white px-2 py-0.5 text-xs dark:border-slate-600 dark:bg-slate-800"
          >
            <option value="cyanea" selected={@cell["language"] == "cyanea"}>Cyanea</option>
            <option value="elixir" selected={@cell["language"] == "elixir"}>Elixir</option>
            <option value="python" selected={@cell["language"] == "python"}>Python</option>
            <option value="r" selected={@cell["language"] == "r"}>R</option>
            <option value="bash" selected={@cell["language"] == "bash"}>Bash</option>
            <option value="sql" selected={@cell["language"] == "sql"}>SQL</option>
          </select>
          <%= if @is_cyanea do %>
            <button
              phx-click="run-cell"
              phx-value-cell-id={@cell["id"]}
              class="rounded p-1 text-emerald-600 hover:bg-emerald-50 hover:text-emerald-700 dark:text-emerald-400 dark:hover:bg-emerald-900/20"
              title="Run cell (Shift+Enter)"
            >
              <.icon name="hero-play" class="h-3.5 w-3.5" />
            </button>
          <% end %>
          <.cell_toolbar cell_id={@cell["id"]} />
        </div>
      </div>

      <%!-- Editor area --%>
      <%= if @is_cyanea do %>
        <div
          id={"code-editor-#{@cell["id"]}"}
          phx-hook="CodeEditor"
          phx-update="ignore"
          data-cell-id={@cell["id"]}
          data-language={@cell["language"]}
          data-source={@cell["source"] || ""}
          class="min-h-[60px]"
        />
      <% else %>
        <textarea
          phx-blur="update-cell"
          phx-value-cell-id={@cell["id"]}
          name="source"
          rows={max(3, length(String.split(@cell["source"] || "", "\n")))}
          class="w-full border-0 bg-slate-50 p-4 font-mono text-sm focus:ring-0 dark:bg-slate-900 dark:text-slate-200"
          spellcheck="false"
        ><%= @cell["source"] %></textarea>
      <% end %>

      <%!-- Running spinner --%>
      <div
        :if={@running}
        class="flex items-center gap-2 border-t border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 px-4 py-2"
      >
        <svg class="h-4 w-4 animate-spin text-primary" viewBox="0 0 24 24" fill="none">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
        <span class="text-xs text-slate-500">Running...</span>
      </div>

      <%!-- Output area --%>
      <div
        :if={@cell_output}
        class="border-t border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900"
      >
        <div class="flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 px-4 py-1">
          <span class="text-[10px] font-medium text-slate-400">OUTPUT</span>
          <span
            :if={@cell_output["timing_ms"]}
            class="text-[10px] text-slate-400"
          >
            <%= @cell_output["timing_ms"] %>ms
          </span>
        </div>
        <div
          id={"output-#{@cell["id"]}"}
          phx-hook="OutputRenderer"
          data-output={Jason.encode!(@cell_output)}
          class="p-4"
        />
      </div>
    </.card>
    """
  end

  defp cell_editor(assigns) do
    ~H"""
    <.card>
      <pre class="text-sm text-slate-600 dark:text-slate-400"><%= @cell["source"] || @cell["content"] || "" %></pre>
    </.card>
    """
  end

  # -- Cell Viewer (read-only view) --

  defp cell_viewer(%{cell: %{"type" => "markdown"}} = assigns) do
    ~H"""
    <.card>
      <div class="prose prose-sm max-w-none dark:prose-invert">
        <%= Markdown.render(@cell["source"]) %>
      </div>
    </.card>
    """
  end

  defp cell_viewer(%{cell: %{"type" => "code"}} = assigns) do
    ~H"""
    <.card padding="p-0">
      <div class="border-b border-slate-200 bg-slate-50 px-4 py-1.5 dark:border-slate-700 dark:bg-slate-900/50">
        <span class="text-xs font-medium text-slate-500">
          <%= String.upcase(@cell["language"] || "code") %>
        </span>
      </div>
      <pre class="overflow-x-auto p-4 font-mono text-sm text-slate-800 dark:text-slate-200"><code><%= @cell["source"] %></code></pre>
    </.card>
    """
  end

  defp cell_viewer(assigns) do
    ~H"""
    <.card>
      <pre class="text-sm text-slate-600 dark:text-slate-400"><%= @cell["source"] || @cell["content"] || "" %></pre>
    </.card>
    """
  end

  # -- Cell toolbar --

  defp cell_toolbar(assigns) do
    ~H"""
    <button
      phx-click="move-cell"
      phx-value-cell-id={@cell_id}
      phx-value-direction="up"
      class="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-700"
      title="Move up"
    >
      <.icon name="hero-chevron-up" class="h-3.5 w-3.5" />
    </button>
    <button
      phx-click="move-cell"
      phx-value-cell-id={@cell_id}
      phx-value-direction="down"
      class="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-700"
      title="Move down"
    >
      <.icon name="hero-chevron-down" class="h-3.5 w-3.5" />
    </button>
    <button
      phx-click="delete-cell"
      phx-value-cell-id={@cell_id}
      data-confirm="Delete this cell?"
      class="rounded p-1 text-slate-400 hover:bg-red-50 hover:text-red-500 dark:hover:bg-red-900/20"
      title="Delete cell"
    >
      <.icon name="hero-trash" class="h-3.5 w-3.5" />
    </button>
    """
  end

  defp has_executable_cells?(cells) do
    Enum.any?(cells, &Notebooks.executable_cell?/1)
  end

  defp save_status_to_indicator(:saved), do: :online
  defp save_status_to_indicator(:saving), do: :syncing
  defp save_status_to_indicator(:unsaved), do: :pending

  defp save_status_label(:saved), do: "Saved"
  defp save_status_label(:saving), do: "Saving..."
  defp save_status_label(:unsaved), do: "Unsaved changes"
end

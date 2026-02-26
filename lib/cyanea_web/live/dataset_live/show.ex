defmodule CyaneaWeb.DatasetLive.Show do
  use CyaneaWeb, :live_view

  alias Cyanea.Blobs
  alias Cyanea.Datasets
  alias Cyanea.Workers.MetadataExtractionWorker
  alias CyaneaWeb.ContentHelpers

  @impl true
  def mount(%{"dataset_slug" => dataset_slug} = params, _session, socket) do
    case ContentHelpers.mount_space(socket, params) do
      {:ok, socket} ->
        mount_dataset(socket, dataset_slug)

      {:error, socket} ->
        {:ok, socket}
    end
  end

  defp mount_dataset(socket, dataset_slug) do
    space = socket.assigns.space
    dataset = Datasets.get_dataset_by_slug(space.id, dataset_slug)

    if dataset do
      files = Datasets.list_dataset_files(dataset.id)
      stats = Datasets.compute_stats(dataset.id)

      socket =
        socket
        |> assign(
          page_title: dataset.name,
          dataset: dataset,
          files: files,
          stats: stats,
          active_tab: "files",
          editing_metadata: false,
          tags_input: Enum.join(dataset.tags || [], ", ")
        )

      socket =
        if socket.assigns.is_owner do
          allow_upload(socket, :dataset_files,
            accept: :any,
            max_entries: 10,
            max_file_size: 500_000_000
          )
        else
          socket
        end

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Dataset not found.")
       |> redirect(to: ~p"/#{socket.assigns.owner_name}/#{space.slug}")}
    end
  end

  @impl true
  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :dataset_files, ref)}
  end

  def handle_event("upload", _params, socket) do
    dataset = socket.assigns.dataset

    uploaded_files =
      consume_uploaded_entries(socket, :dataset_files, fn %{path: path}, entry ->
        mime = entry.client_type || "application/octet-stream"
        name = entry.client_name

        with {:ok, blob} <- Blobs.create_blob_from_upload(path, mime_type: mime),
             {:ok, df} <- Datasets.attach_file(dataset, blob.id, name, size: blob.size) do
          # Enqueue metadata extraction with dataset_id
          %{blob_id: blob.id, dataset_id: dataset.id}
          |> MetadataExtractionWorker.new()
          |> Oban.insert()

          {:ok, df}
        else
          {:error, reason} -> {:postpone, reason}
        end
      end)

    files = Datasets.list_dataset_files(dataset.id)
    stats = Datasets.compute_stats(dataset.id)

    socket =
      if Enum.any?(uploaded_files) do
        put_flash(socket, :info, "#{length(uploaded_files)} file(s) uploaded.")
      else
        socket
      end

    {:noreply, assign(socket, files: files, stats: stats)}
  end

  def handle_event("delete-file", %{"id" => file_id}, socket) do
    case Datasets.detach_file(file_id) do
      {:ok, _} ->
        files = Datasets.list_dataset_files(socket.assigns.dataset.id)
        stats = Datasets.compute_stats(socket.assigns.dataset.id)

        {:noreply,
         socket
         |> put_flash(:info, "File removed.")
         |> assign(files: files, stats: stats)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove file.")}
    end
  end

  def handle_event("edit-metadata", _params, socket) do
    {:noreply, assign(socket, editing_metadata: true)}
  end

  def handle_event("save-metadata", params, socket) do
    dataset = socket.assigns.dataset

    updates = %{}

    updates =
      if params["description"],
        do: Map.put(updates, :description, params["description"]),
        else: updates

    tags =
      if params["tags"] do
        params["tags"]
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      else
        dataset.tags
      end

    with {:ok, dataset} <- Datasets.update_dataset(dataset, updates),
         {:ok, dataset} <- Datasets.update_tags(dataset, tags) do
      {:noreply,
       socket
       |> assign(
         dataset: dataset,
         editing_metadata: false,
         tags_input: Enum.join(dataset.tags || [], ", ")
       )
       |> put_flash(:info, "Metadata saved.")}
    else
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save metadata.")}
    end
  end

  def handle_event("cancel-edit", _params, socket) do
    {:noreply, assign(socket, editing_metadata: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Breadcrumb --%>
      <.breadcrumb>
        <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
        <:crumb navigate={~p"/#{@owner_name}/#{@space.slug}"}><%= @space.name %></:crumb>
        <:crumb><%= @dataset.name %></:crumb>
      </.breadcrumb>

      <%!-- Dataset info --%>
      <div class="mt-6 flex items-start justify-between">
        <div>
          <h1 class="text-2xl font-bold text-slate-900 dark:text-white"><%= @dataset.name %></h1>
          <p :if={@dataset.description} class="mt-1 text-sm text-slate-600 dark:text-slate-400">
            <%= @dataset.description %>
          </p>
          <div :if={@dataset.tags != []} class="mt-2 flex flex-wrap gap-1">
            <.badge :for={tag <- @dataset.tags} color={:primary} size={:xs}><%= tag %></.badge>
          </div>
        </div>
        <div class="flex items-center gap-4 text-center">
          <.stat value={@stats.file_count} label="Files" />
          <.stat value={format_size(@stats.total_size)} label="Total size" />
        </div>
      </div>

      <%!-- Tabs --%>
      <div class="mt-6">
        <.tabs>
          <:tab active={@active_tab == "files"} click="switch-tab" value="files" count={@stats.file_count}>
            Files
          </:tab>
          <:tab active={@active_tab == "preview"} click="switch-tab" value="preview">
            Preview
          </:tab>
          <:tab active={@active_tab == "metadata"} click="switch-tab" value="metadata">
            Metadata
          </:tab>
        </.tabs>
      </div>

      <div class="mt-6">
        <%!-- Files tab --%>
        <div :if={@active_tab == "files"}>
          <%!-- Upload zone (owner only) --%>
          <div :if={@is_owner} class="mb-6">
            <form phx-change="validate-upload" phx-submit="upload">
              <.upload_zone upload={@uploads.dataset_files} />
              <div :for={err <- upload_errors(@uploads.dataset_files)} class="mt-2 text-sm text-red-600">
                <%= upload_error_to_string(err) %>
              </div>
              <button
                :if={@uploads.dataset_files.entries != []}
                type="submit"
                class="mt-3 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
              >
                Upload files
              </button>
            </form>
          </div>

          <.card padding="p-0">
            <div :if={@files != []}>
              <table class="w-full">
                <tbody>
                  <tr
                    :for={file <- @files}
                    class="border-b border-slate-100 last:border-0 dark:border-slate-700"
                  >
                    <td class="px-6 py-3">
                      <div class="flex items-center gap-3">
                        <.icon name="hero-document" class="h-5 w-5 text-slate-400 shrink-0" />
                        <.link
                          :if={file.blob}
                          href={~p"/blobs/#{file.blob_id}/download"}
                          class="text-sm font-medium text-primary hover:underline"
                        >
                          <%= file.path %>
                        </.link>
                        <span :if={!file.blob} class="text-sm font-medium text-slate-900 dark:text-white"><%= file.path %></span>
                      </div>
                    </td>
                    <td class="px-6 py-3 text-right text-xs text-slate-500">
                      <%= format_size(file.size || 0) %>
                    </td>
                    <td class="px-6 py-3 text-right text-xs text-slate-500">
                      <%= if file.blob, do: file.blob.mime_type || "-", else: "-" %>
                    </td>
                    <td class="px-6 py-3 text-right">
                      <div class="flex items-center justify-end gap-2">
                        <.link
                          :if={file.blob}
                          href={~p"/blobs/#{file.blob_id}/download"}
                          class="text-xs text-primary hover:text-primary/80"
                        >
                          Download
                        </.link>
                        <button
                          :if={@is_owner}
                          phx-click="delete-file"
                          phx-value-id={file.id}
                          data-confirm="Remove this file?"
                          class="text-xs text-red-500 hover:text-red-700"
                        >
                          Remove
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div :if={@files == []} class="px-6 py-12">
              <.empty_state
                icon="hero-folder-open"
                heading="No files yet."
                description="Upload files to this dataset to get started."
              />
            </div>
          </.card>
        </div>

        <%!-- Preview tab --%>
        <div :if={@active_tab == "preview"}>
          <.card>
            <%= if has_csv_stats?(@dataset) do %>
              <.preview_csv_stats metadata={@dataset.metadata} />
            <% else %>
              <%= if has_sequence_stats?(@dataset) do %>
                <.preview_sequence_stats metadata={@dataset.metadata} />
              <% else %>
                <.empty_state
                  icon="hero-eye"
                  heading="No preview available."
                  description="Upload a CSV or sequence file to see a preview."
                />
              <% end %>
            <% end %>
          </.card>
        </div>

        <%!-- Metadata tab --%>
        <div :if={@active_tab == "metadata"}>
          <.card>
            <%= if @editing_metadata do %>
              <form phx-submit="save-metadata" class="space-y-4">
                <div>
                  <label class="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Description</label>
                  <textarea
                    name="description"
                    rows="3"
                    class="w-full rounded-lg border border-slate-200 p-3 text-sm dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200"
                  ><%= @dataset.description %></textarea>
                </div>
                <div>
                  <label class="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Tags (comma-separated)</label>
                  <input
                    type="text"
                    name="tags"
                    value={@tags_input}
                    class="w-full rounded-lg border border-slate-200 p-3 text-sm dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200"
                  />
                </div>
                <div class="flex justify-end gap-2">
                  <button type="button" phx-click="cancel-edit" class="text-sm text-slate-500 hover:text-slate-700">Cancel</button>
                  <button type="submit" class="rounded-lg bg-primary px-3 py-1.5 text-sm font-medium text-white hover:bg-primary/90">Save</button>
                </div>
              </form>
            <% else %>
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Dataset metadata</h3>
                <button
                  :if={@is_owner}
                  phx-click="edit-metadata"
                  class="text-xs font-medium text-primary hover:text-primary/80"
                >
                  Edit
                </button>
              </div>
              <.description_list>
                <:item term="Name"><%= @dataset.name %></:item>
                <:item term="Storage"><%= @dataset.storage_type %></:item>
                <:item term="External URL"><%= @dataset.external_url || "-" %></:item>
                <:item term="Files"><%= @stats.file_count %></:item>
                <:item term="Total size"><%= format_size(@stats.total_size) %></:item>
                <:item term="Formats"><%= Enum.join(@stats.formats, ", ") %></:item>
                <:item term="Tags"><%= Enum.join(@dataset.tags || [], ", ") %></:item>
              </.description_list>
            <% end %>
          </.card>
        </div>
      </div>
    </div>
    """
  end

  # -- Preview components --

  defp preview_csv_stats(assigns) do
    ~H"""
    <div>
      <h3 class="mb-3 text-sm font-semibold text-slate-900 dark:text-white">CSV Statistics</h3>
      <.description_list>
        <:item :if={@metadata["row_count"]} term="Rows"><%= @metadata["row_count"] %></:item>
        <:item :if={@metadata["column_count"]} term="Columns"><%= @metadata["column_count"] %></:item>
        <:item :if={@metadata["columns"]} term="Column names"><%= Enum.join(@metadata["columns"], ", ") %></:item>
      </.description_list>
    </div>
    """
  end

  defp preview_sequence_stats(assigns) do
    ~H"""
    <div>
      <h3 class="mb-3 text-sm font-semibold text-slate-900 dark:text-white">Sequence Statistics</h3>
      <.description_list>
        <:item :if={@metadata["sequence_count"]} term="Sequences"><%= @metadata["sequence_count"] %></:item>
        <:item :if={@metadata["total_length"]} term="Total length"><%= @metadata["total_length"] %> bp</:item>
        <:item :if={@metadata["gc_content"]} term="GC content"><%= Float.round(@metadata["gc_content"] * 100, 1) %>%</:item>
      </.description_list>
    </div>
    """
  end

  # -- Helpers --

  defp has_csv_stats?(dataset) do
    meta = dataset.metadata || %{}
    Map.has_key?(meta, "row_count") or Map.has_key?(meta, "column_count")
  end

  defp has_sequence_stats?(dataset) do
    meta = dataset.metadata || %{}
    Map.has_key?(meta, "sequence_count")
  end

  defp format_size(0), do: "0 B"
  defp format_size(nil), do: "0 B"

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"

  defp format_size(bytes) when bytes < 1_048_576,
    do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_size(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp format_size(bytes),
    do: "#{Float.round(bytes / 1_073_741_824, 1)} GB"

  defp upload_error_to_string(:too_large), do: "File is too large (max 500 MB)."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 10)."
  defp upload_error_to_string(:external_client_failure), do: "Upload failed."
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"
end

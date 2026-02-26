defmodule CyaneaWeb.FilePreviewLive do
  use CyaneaWeb, :live_view

  import CyaneaWeb.PreviewComponents

  alias Cyanea.Previews
  alias Cyanea.Spaces
  alias Cyanea.Storage

  @impl true
  def mount(%{"username" => owner_name, "slug" => slug, "file_id" => file_id}, _session, socket) do
    space = Spaces.get_space_by_owner_and_slug(owner_name, slug)
    current_user = socket.assigns[:current_user]

    cond do
      is_nil(space) ->
        {:ok,
         socket
         |> put_flash(:error, "Space not found.")
         |> redirect(to: ~p"/explore")}

      not Spaces.can_access?(space, current_user) ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this space.")
         |> redirect(to: ~p"/explore")}

      true ->
        mount_file_preview(socket, space, owner_name, file_id)
    end
  end

  defp mount_file_preview(socket, space, owner_name, file_id) do
    case Cyanea.Repo.get(Cyanea.Blobs.SpaceFile, file_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "File not found.")
         |> redirect(to: ~p"/#{owner_name}/#{space.slug}")}

      file ->
        file = Cyanea.Repo.preload(file, :blob)
        blob = file.blob

        {preview_type, preview_data} =
          case Previews.get_or_generate_preview(blob, file.name) do
            {:ok, preview} ->
              {preview.preview_type, preview.preview_data}

            {:error, _} ->
              type = Previews.preview_type(file.name, blob.mime_type)
              {Atom.to_string(type), %{}}
          end

        download_url =
          case Storage.presigned_download_url(blob.s3_key) do
            {:ok, url} -> url
            _ -> ~p"/blobs/#{blob.id}/download"
          end

        {:ok,
         assign(socket,
           page_title: file.name,
           space: space,
           owner_name: owner_name,
           file: file,
           blob: blob,
           preview_type: preview_type,
           preview_data: preview_data,
           download_url: download_url
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.breadcrumb>
        <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
        <:crumb navigate={~p"/#{@owner_name}/#{@space.slug}"}><%= @space.name %></:crumb>
        <:crumb>Files</:crumb>
        <:crumb><%= @file.name %></:crumb>
      </.breadcrumb>

      <div class="mt-6 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <.icon name="hero-document" class="h-6 w-6 text-slate-400" />
          <div>
            <h1 class="text-lg font-semibold text-slate-900 dark:text-white"><%= @file.name %></h1>
            <p class="text-xs text-slate-500">
              <%= CyaneaWeb.Formatters.format_size(@blob.size) %>
              <span :if={@blob.mime_type}>&middot; <%= @blob.mime_type %></span>
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <.badge color={preview_type_color(@preview_type)}><%= @preview_type %></.badge>
          <.link
            href={@download_url}
            class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
          >
            <.icon name="hero-arrow-down-tray" class="h-4 w-4" />
            Download
          </.link>
        </div>
      </div>

      <div class="mt-6">
        <.card>
          <.file_preview
            preview_type={@preview_type}
            preview_data={@preview_data}
            download_url={@download_url}
            blob={@blob}
          />
        </.card>
      </div>
    </div>
    """
  end

  defp preview_type_color("sequence"), do: :emerald
  defp preview_type_color("tabular"), do: :primary
  defp preview_type_color("variant"), do: :violet
  defp preview_type_color("interval"), do: :amber
  defp preview_type_color("structure"), do: :rose
  defp preview_type_color("image"), do: :success
  defp preview_type_color("pdf"), do: :error
  defp preview_type_color("markdown"), do: :accent
  defp preview_type_color("text"), do: :gray
  defp preview_type_color(_), do: :gray
end

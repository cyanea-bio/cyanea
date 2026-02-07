defmodule CyaneaWeb.RepositoryLive.Show do
  use CyaneaWeb, :live_view

  alias Cyanea.Repositories
  alias Cyanea.Files

  @impl true
  def mount(%{"username" => owner_name, "slug" => slug}, _session, socket) do
    # Try user-owned first, then org-owned
    repo =
      Repositories.get_repository_by_owner_and_slug(owner_name, slug) ||
        Repositories.get_repository_by_org_and_slug(owner_name, slug)

    current_user = socket.assigns[:current_user]

    cond do
      is_nil(repo) ->
        {:ok,
         socket
         |> put_flash(:error, "Repository not found.")
         |> redirect(to: ~p"/explore")}

      not Repositories.can_access?(repo, current_user) ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this repository.")
         |> redirect(to: ~p"/explore")}

      true ->
        owner_display = repo_owner_display(repo)
        is_owner = current_user && is_repo_owner?(repo, current_user)
        files = Files.list_repository_files(repo.id)

        socket =
          socket
          |> assign(
            page_title: "#{owner_display}/#{repo.name}",
            repo: repo,
            owner_display: owner_display,
            is_owner: is_owner,
            files: files
          )

        socket =
          if is_owner do
            allow_upload(socket, :files,
              accept: :any,
              max_entries: 5,
              max_file_size: 100_000_000
            )
          else
            socket
          end

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  def handle_event("upload", _params, socket) do
    repo = socket.assigns.repo

    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        mime = entry.client_type || "application/octet-stream"
        name = entry.client_name
        file_path = name

        attrs = %{
          repository_id: repo.id,
          path: file_path,
          name: name,
          type: "file",
          mime_type: mime
        }

        case Files.create_file_from_upload(path, attrs) do
          {:ok, file} -> {:ok, file}
          {:error, reason} -> {:postpone, reason}
        end
      end)

    files = Files.list_repository_files(repo.id)

    socket =
      if Enum.any?(uploaded_files) do
        put_flash(socket, :info, "#{length(uploaded_files)} file(s) uploaded.")
      else
        socket
      end

    {:noreply, assign(socket, files: files)}
  end

  def handle_event("delete-file", %{"id" => file_id}, socket) do
    file = Files.get_file!(file_id)

    case Files.delete_file(file) do
      {:ok, _} ->
        files = Files.list_repository_files(socket.assigns.repo.id)
        {:noreply, socket |> put_flash(:info, "File deleted.") |> assign(files: files)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete file.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Breadcrumb --%>
      <div class="flex items-center gap-2 text-sm text-slate-500">
        <.link navigate={owner_path(@repo)} class="hover:text-primary">
          <%= @owner_display %>
        </.link>
        <span>/</span>
        <span class="font-semibold text-slate-900 dark:text-white"><%= @repo.name %></span>
        <span class={[
          "ml-2 inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
          if(@repo.visibility == "public",
            do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
            else: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
          )
        ]}>
          <%= @repo.visibility %>
        </span>
      </div>

      <%!-- Repository Info Card --%>
      <div class="mt-6 rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-800">
        <div class="flex items-start justify-between">
          <div>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white"><%= @repo.name %></h1>
            <p :if={@repo.description} class="mt-2 text-slate-600 dark:text-slate-400">
              <%= @repo.description %>
            </p>
          </div>
          <div class="flex items-center gap-3">
            <span class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm dark:border-slate-700">
              <.icon name="hero-star" class="h-4 w-4" />
              <%= @repo.stars_count %>
            </span>
          </div>
        </div>

        <%!-- Metadata --%>
        <div class="mt-4 flex flex-wrap items-center gap-4 text-sm text-slate-500">
          <span :if={@repo.license} class="flex items-center gap-1">
            <.icon name="hero-scale" class="h-4 w-4" />
            <%= license_display(@repo.license) %>
          </span>
          <span class="flex items-center gap-1">
            <.icon name="hero-clock" class="h-4 w-4" />
            Updated <%= format_date(@repo.updated_at) %>
          </span>
          <span :if={@repo.default_branch} class="flex items-center gap-1">
            <.icon name="hero-code-bracket" class="h-4 w-4" />
            <%= @repo.default_branch %>
          </span>
        </div>

        <%!-- Tags --%>
        <div :if={@repo.tags != []} class="mt-4 flex flex-wrap gap-2">
          <span
            :for={tag <- @repo.tags}
            class="rounded-full bg-primary-100 px-2.5 py-0.5 text-xs font-medium text-primary-700 dark:bg-primary-900/30 dark:text-primary-400"
          >
            <%= tag %>
          </span>
        </div>
      </div>

      <%!-- Upload zone (owner only) --%>
      <div :if={@is_owner} class="mt-6 rounded-xl border-2 border-dashed border-slate-300 bg-white p-6 dark:border-slate-600 dark:bg-slate-800">
        <form id="upload-form" phx-change="validate-upload" phx-submit="upload" phx-drop-target={@uploads.files.ref}>
          <div class="text-center">
            <.icon name="hero-cloud-arrow-up" class="mx-auto h-10 w-10 text-slate-400" />
            <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
              Drag and drop files here, or
              <label class="cursor-pointer font-medium text-primary hover:text-primary-500">
                browse
                <.live_file_input upload={@uploads.files} class="sr-only" />
              </label>
            </p>
            <p class="mt-1 text-xs text-slate-400">Up to 5 files, 100 MB each</p>
          </div>

          <%!-- Upload entries --%>
          <div :if={@uploads.files.entries != []} class="mt-4 space-y-2">
            <div :for={entry <- @uploads.files.entries} class="flex items-center justify-between rounded-lg border border-slate-200 p-3 dark:border-slate-700">
              <div class="flex items-center gap-3 min-w-0 flex-1">
                <.icon name="hero-document" class="h-5 w-5 text-slate-400 shrink-0" />
                <span class="truncate text-sm"><%= entry.client_name %></span>
                <span class="text-xs text-slate-400"><%= format_size(entry.client_size) %></span>
              </div>
              <div class="flex items-center gap-2">
                <div class="h-1.5 w-20 rounded-full bg-slate-200 dark:bg-slate-700">
                  <div class="h-1.5 rounded-full bg-primary" style={"width: #{entry.progress}%"}></div>
                </div>
                <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-slate-400 hover:text-red-500">
                  <.icon name="hero-x-mark" class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>

          <div :if={@uploads.files.entries != []} class="mt-4 text-center">
            <.button type="submit" phx-disable-with="Uploading...">Upload files</.button>
          </div>

          <%!-- Upload errors --%>
          <div :for={err <- upload_errors(@uploads.files)} class="mt-2 text-sm text-red-600">
            <%= upload_error_to_string(err) %>
          </div>
        </form>
      </div>

      <%!-- File listing --%>
      <div class="mt-6 rounded-xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800">
        <div class="border-b border-slate-200 px-6 py-4 dark:border-slate-700">
          <div class="flex items-center justify-between">
            <h2 class="text-sm font-semibold text-slate-900 dark:text-white">Files</h2>
            <span :if={@files != []} class="text-xs text-slate-500"><%= length(@files) %> file(s)</span>
          </div>
        </div>

        <div :if={@files != []}>
          <table class="w-full">
            <tbody>
              <tr
                :for={file <- @files}
                class="border-b border-slate-100 last:border-0 dark:border-slate-700"
              >
                <td class="px-6 py-3">
                  <div class="flex items-center gap-3">
                    <.icon name={file_icon(file.type)} class="h-5 w-5 text-slate-400 shrink-0" />
                    <span class="text-sm font-medium text-slate-900 dark:text-white"><%= file.name %></span>
                  </div>
                </td>
                <td class="px-6 py-3 text-right text-xs text-slate-500">
                  <%= if file.size, do: format_size(file.size), else: "-" %>
                </td>
                <td class="px-6 py-3 text-right text-xs text-slate-500">
                  <%= file.mime_type || "-" %>
                </td>
                <td class="px-6 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <.link
                      href={~p"/files/#{file.id}/download"}
                      class="text-xs text-primary hover:text-primary-700"
                    >
                      Download
                    </.link>
                    <button
                      :if={@is_owner}
                      phx-click="delete-file"
                      phx-value-id={file.id}
                      data-confirm="Delete this file?"
                      class="text-xs text-red-500 hover:text-red-700"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={@files == []} class="px-6 py-12 text-center text-sm text-slate-500 dark:text-slate-400">
          <.icon name="hero-folder-open" class="mx-auto mb-3 h-12 w-12 text-slate-300 dark:text-slate-600" />
          <p>No files uploaded yet.</p>
          <p class="mt-1">Upload datasets, protocols, and research artifacts to get started.</p>
        </div>
      </div>
    </div>
    """
  end

  defp repo_owner_display(repo) do
    cond do
      repo.owner -> repo.owner.username
      repo.organization -> repo.organization.slug
      true -> "unknown"
    end
  end

  defp owner_path(repo) do
    cond do
      repo.owner -> ~p"/#{repo.owner.username}"
      repo.organization -> ~p"/#{repo.organization.slug}"
      true -> ~p"/"
    end
  end

  defp is_repo_owner?(repo, user) do
    repo.owner_id == user.id
  end

  defp file_icon("directory"), do: "hero-folder"
  defp file_icon(_), do: "hero-document"

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes) when bytes < 1_073_741_824, do: "#{Float.round(bytes / 1_048_576, 1)} MB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_073_741_824, 1)} GB"

  defp upload_error_to_string(:too_large), do: "File is too large (max 100 MB)."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 5)."
  defp upload_error_to_string(:external_client_failure), do: "Upload failed."
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"

  defp license_display("cc-by-4.0"), do: "CC BY 4.0"
  defp license_display("cc-by-sa-4.0"), do: "CC BY-SA 4.0"
  defp license_display("cc0-1.0"), do: "CC0 1.0"
  defp license_display("mit"), do: "MIT"
  defp license_display("apache-2.0"), do: "Apache 2.0"
  defp license_display("proprietary"), do: "Proprietary"
  defp license_display(other), do: other

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end
end

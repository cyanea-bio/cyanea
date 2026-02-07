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
      <div class="flex items-center gap-3">
        <.breadcrumb>
          <:crumb navigate={owner_path(@repo)}><%= @owner_display %></:crumb>
          <:crumb><%= @repo.name %></:crumb>
        </.breadcrumb>
        <.visibility_badge visibility={@repo.visibility} />
      </div>

      <%!-- Repository Info Card --%>
      <.card class="mt-6">
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
        <div class="mt-4 flex flex-wrap items-center gap-4">
          <.metadata_row :if={@repo.license} icon="hero-scale">
            <%= CyaneaWeb.Formatters.license_display(@repo.license) %>
          </.metadata_row>
          <.metadata_row icon="hero-clock">
            Updated <%= CyaneaWeb.Formatters.format_date(@repo.updated_at) %>
          </.metadata_row>
          <.metadata_row :if={@repo.default_branch} icon="hero-code-bracket">
            <%= @repo.default_branch %>
          </.metadata_row>
        </div>

        <%!-- Tags --%>
        <div :if={@repo.tags != []} class="mt-4 flex flex-wrap gap-2">
          <.badge :for={tag <- @repo.tags} color={:primary}><%= tag %></.badge>
        </div>
      </.card>

      <%!-- Upload zone (owner only) --%>
      <div :if={@is_owner} class="mt-6">
        <.upload_zone upload={@uploads.files} />
        <%!-- Upload errors --%>
        <div :for={err <- upload_errors(@uploads.files)} class="mt-2 text-sm text-red-600">
          <%= upload_error_to_string(err) %>
        </div>
      </div>

      <%!-- File listing --%>
      <.card padding="p-0" class="mt-6">
        <:header>
          <div class="flex items-center justify-between">
            <h2 class="text-sm font-semibold text-slate-900 dark:text-white">Files</h2>
            <span :if={@files != []} class="text-xs text-slate-500"><%= length(@files) %> file(s)</span>
          </div>
        </:header>

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
                  <%= if file.size, do: CyaneaWeb.Formatters.format_size(file.size), else: "-" %>
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

        <div :if={@files == []} class="px-6 py-12">
          <.empty_state
            icon="hero-folder-open"
            heading="No files uploaded yet."
            description="Upload datasets, protocols, and research artifacts to get started."
          />
        </div>
      </.card>
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

  defp upload_error_to_string(:too_large), do: "File is too large (max 100 MB)."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 5)."
  defp upload_error_to_string(:external_client_failure), do: "Upload failed."
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"
end

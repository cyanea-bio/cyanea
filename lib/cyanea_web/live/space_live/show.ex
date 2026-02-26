defmodule CyaneaWeb.SpaceLive.Show do
  use CyaneaWeb, :live_view

  import CyaneaWeb.ActivityEventComponent

  alias Cyanea.Activity
  alias Cyanea.Blobs
  alias Cyanea.Datasets
  alias Cyanea.Notebooks
  alias Cyanea.Notifications
  alias Cyanea.Protocols
  alias Cyanea.Spaces
  alias Cyanea.Stars

  @impl true
  def mount(%{"username" => owner_name, "slug" => slug}, _session, socket) do
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
        is_owner = current_user && Spaces.owner?(space, current_user)
        files = Blobs.list_space_files(space.id)
        notebooks = Notebooks.list_space_notebooks(space.id)
        protocols = Protocols.list_space_protocols(space.id)
        datasets = Datasets.list_space_datasets(space.id)
        starred = current_user && Stars.starred?(current_user.id, space.id)

        # Load forked-from space info
        forked_from = load_forked_from(space)

        socket =
          socket
          |> assign(
            page_title: "#{owner_name}/#{space.name}",
            space: space,
            owner_name: owner_name,
            is_owner: is_owner,
            files: files,
            notebooks: notebooks,
            protocols: protocols,
            datasets: datasets,
            starred: starred || false,
            active_tab: "overview",
            forked_from: forked_from,
            activity_events: []
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
  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    socket =
      if tab == "activity" && socket.assigns.activity_events == [] do
        events = Activity.list_space_feed(socket.assigns.space.id, limit: 20)
        assign(socket, activity_events: events)
      else
        socket
      end

    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  def handle_event("upload", _params, socket) do
    space = socket.assigns.space

    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        mime = entry.client_type || "application/octet-stream"
        name = entry.client_name

        with {:ok, blob} <- Blobs.create_blob_from_upload(path, mime_type: mime),
             {:ok, sf} <- Blobs.attach_file_to_space(space.id, blob.id, name, name) do
          {:ok, sf}
        else
          {:error, reason} -> {:postpone, reason}
        end
      end)

    files = Blobs.list_space_files(space.id)

    socket =
      if Enum.any?(uploaded_files) do
        put_flash(socket, :info, "#{length(uploaded_files)} file(s) uploaded.")
      else
        socket
      end

    {:noreply, assign(socket, files: files)}
  end

  def handle_event("delete-file", %{"id" => file_id}, socket) do
    case Blobs.detach_file_from_space(file_id) do
      {:ok, _} ->
        files = Blobs.list_space_files(socket.assigns.space.id)
        {:noreply, socket |> put_flash(:info, "File removed.") |> assign(files: files)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove file.")}
    end
  end

  def handle_event("star", _params, socket) do
    user = socket.assigns.current_user
    space = socket.assigns.space

    case Stars.star_space(user.id, space.id) do
      {:ok, _star} ->
        Activity.log(user, "starred_space", space,
          space_id: space.id,
          metadata: %{"name" => space.name, "slug" => space.slug}
        )

        Notifications.notify_space_owner(user, "starred", space, "space", space.id)

        space = Spaces.get_space!(space.id)
        {:noreply, assign(socket, starred: true, space: space)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("unstar", _params, socket) do
    user = socket.assigns.current_user
    space = socket.assigns.space

    case Stars.unstar_space(user.id, space.id) do
      :ok ->
        space = Spaces.get_space!(space.id)
        {:noreply, assign(socket, starred: false, space: space)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("fork", _params, socket) do
    user = socket.assigns.current_user
    space = socket.assigns.space

    case Spaces.fork_space(space, user) do
      {:ok, forked_space} ->
        Activity.log(user, "forked_space", forked_space,
          space_id: forked_space.id,
          metadata: %{
            "name" => forked_space.name,
            "slug" => forked_space.slug,
            "original_id" => space.id
          }
        )

        Notifications.notify_space_owner(user, "forked", space, "space", forked_space.id)

        {:noreply,
         socket
         |> put_flash(:info, "Space forked successfully.")
         |> redirect(to: ~p"/#{user.username}/#{forked_space.slug}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to fork space.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Breadcrumb --%>
      <div class="flex items-center gap-3">
        <.breadcrumb>
          <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
          <:crumb><%= @space.name %></:crumb>
        </.breadcrumb>
        <.visibility_badge visibility={@space.visibility} />
      </div>

      <%!-- Forked from attribution --%>
      <p :if={@forked_from} class="mt-2 text-sm text-slate-500">
        Forked from
        <.link
          navigate={~p"/#{@forked_from.owner_name}/#{@forked_from.slug}"}
          class="font-medium text-primary hover:underline"
        >
          <%= @forked_from.owner_name %>/<%= @forked_from.name %>
        </.link>
      </p>

      <%!-- Space Info Card --%>
      <.card class="mt-6">
        <div class="flex items-start justify-between">
          <div>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white"><%= @space.name %></h1>
            <p :if={@space.description} class="mt-2 text-slate-600 dark:text-slate-400">
              <%= @space.description %>
            </p>
          </div>
          <div class="flex items-center gap-3">
            <%= if @current_user do %>
              <%= if @starred do %>
                <button
                  phx-click="unstar"
                  class="flex items-center gap-1 rounded-lg border border-yellow-300 bg-yellow-50 px-3 py-1.5 text-sm text-yellow-700 dark:border-yellow-600 dark:bg-yellow-900/20 dark:text-yellow-400"
                >
                  <.icon name="hero-star-solid" class="h-4 w-4" />
                  <%= @space.star_count %>
                </button>
              <% else %>
                <button
                  phx-click="star"
                  class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm dark:border-slate-700"
                >
                  <.icon name="hero-star" class="h-4 w-4" />
                  <%= @space.star_count %>
                </button>
              <% end %>

              <%!-- Fork button --%>
              <button
                :if={!@is_owner}
                phx-click="fork"
                data-confirm="Fork this space? A copy will be created under your account."
                class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
              >
                <.icon name="hero-arrow-path-rounded-square" class="h-4 w-4" />
                Fork
                <span :if={@space.fork_count > 0} class="text-slate-400"><%= @space.fork_count %></span>
              </button>
            <% else %>
              <span class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm dark:border-slate-700">
                <.icon name="hero-star" class="h-4 w-4" />
                <%= @space.star_count %>
              </span>
              <span :if={@space.fork_count > 0} class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm dark:border-slate-700">
                <.icon name="hero-arrow-path-rounded-square" class="h-4 w-4" />
                <%= @space.fork_count %>
              </span>
            <% end %>
            <.link
              :if={@is_owner}
              navigate={~p"/#{@owner_name}/#{@space.slug}/settings"}
              class="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
            >
              <.icon name="hero-cog-6-tooth" class="h-4 w-4" />
              Settings
            </.link>
          </div>
        </div>

        <%!-- Metadata --%>
        <div class="mt-4 flex flex-wrap items-center gap-4">
          <.metadata_row :if={@space.license} icon="hero-scale">
            <%= CyaneaWeb.Formatters.license_display(@space.license) %>
          </.metadata_row>
          <.metadata_row icon="hero-clock">
            Updated <%= CyaneaWeb.Formatters.format_date(@space.updated_at) %>
          </.metadata_row>
        </div>

        <%!-- Tags --%>
        <div :if={@space.tags != []} class="mt-4 flex flex-wrap gap-2">
          <.badge :for={tag <- @space.tags} color={:primary}><%= tag %></.badge>
        </div>
      </.card>

      <%!-- Tabs --%>
      <div class="mt-6">
        <.tabs>
          <:tab active={@active_tab == "overview"} click="switch-tab" value="overview">
            Overview
          </:tab>
          <:tab active={@active_tab == "notebooks"} click="switch-tab" value="notebooks" count={length(@notebooks)}>
            Notebooks
          </:tab>
          <:tab active={@active_tab == "protocols"} click="switch-tab" value="protocols" count={length(@protocols)}>
            Protocols
          </:tab>
          <:tab active={@active_tab == "datasets"} click="switch-tab" value="datasets" count={length(@datasets)}>
            Datasets
          </:tab>
          <:tab active={@active_tab == "files"} click="switch-tab" value="files" count={length(@files)}>
            Files
          </:tab>
          <:tab active={@active_tab == "discussions"} click="switch-tab" value="discussions" count={@space.discussion_count}>
            Discussions
          </:tab>
          <:tab active={@active_tab == "activity"} click="switch-tab" value="activity">
            Activity
          </:tab>
        </.tabs>
      </div>

      <%!-- Tab content --%>
      <div class="mt-6">
        <%!-- Overview --%>
        <div :if={@active_tab == "overview"}>
          <div class="grid gap-6 md:grid-cols-2">
            <.card>
              <:header>
                <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Contents</h3>
              </:header>
              <.description_list>
                <:item term="Notebooks"><%= length(@notebooks) %></:item>
                <:item term="Protocols"><%= length(@protocols) %></:item>
                <:item term="Datasets"><%= length(@datasets) %></:item>
                <:item term="Files"><%= length(@files) %></:item>
              </.description_list>
            </.card>
          </div>
        </div>

        <%!-- Notebooks --%>
        <div :if={@active_tab == "notebooks"}>
          <div :if={@is_owner} class="mb-4 flex justify-end">
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}/notebooks/new"}
              class="inline-flex items-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-white hover:bg-primary/90"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> New Notebook
            </.link>
          </div>
          <.card padding="p-0">
            <div :if={@notebooks != []} class="divide-y divide-slate-100 dark:divide-slate-700">
              <.link
                :for={notebook <- @notebooks}
                navigate={~p"/#{@owner_name}/#{@space.slug}/notebooks/#{notebook.slug}"}
                class="flex items-center justify-between px-6 py-3 hover:bg-slate-50 dark:hover:bg-slate-700/50"
              >
                <div class="flex items-center gap-3">
                  <.icon name="hero-book-open" class="h-5 w-5 text-slate-400 shrink-0" />
                  <span class="text-sm font-medium text-slate-900 dark:text-white"><%= notebook.title %></span>
                </div>
              </.link>
            </div>
            <div :if={@notebooks == []} class="px-6 py-12">
              <.empty_state icon="hero-book-open" heading="No notebooks yet.">
                <:action>
                  <.link
                    :if={@is_owner}
                    navigate={~p"/#{@owner_name}/#{@space.slug}/notebooks/new"}
                    class="text-sm font-medium text-primary hover:text-primary/80"
                  >
                    Create your first notebook
                  </.link>
                </:action>
              </.empty_state>
            </div>
          </.card>
        </div>

        <%!-- Protocols --%>
        <div :if={@active_tab == "protocols"}>
          <div :if={@is_owner} class="mb-4 flex justify-end">
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}/protocols/new"}
              class="inline-flex items-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-white hover:bg-primary/90"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> New Protocol
            </.link>
          </div>
          <.card padding="p-0">
            <div :if={@protocols != []} class="divide-y divide-slate-100 dark:divide-slate-700">
              <.link
                :for={protocol <- @protocols}
                navigate={~p"/#{@owner_name}/#{@space.slug}/protocols/#{protocol.slug}"}
                class="flex items-center justify-between px-6 py-3 hover:bg-slate-50 dark:hover:bg-slate-700/50"
              >
                <div class="flex items-center gap-3">
                  <.icon name="hero-clipboard-document-list" class="h-5 w-5 text-slate-400 shrink-0" />
                  <div>
                    <span class="text-sm font-medium text-slate-900 dark:text-white"><%= protocol.title %></span>
                    <span class="ml-2 text-xs text-slate-500">v<%= protocol.version %></span>
                  </div>
                </div>
              </.link>
            </div>
            <div :if={@protocols == []} class="px-6 py-12">
              <.empty_state icon="hero-clipboard-document-list" heading="No protocols yet.">
                <:action>
                  <.link
                    :if={@is_owner}
                    navigate={~p"/#{@owner_name}/#{@space.slug}/protocols/new"}
                    class="text-sm font-medium text-primary hover:text-primary/80"
                  >
                    Create your first protocol
                  </.link>
                </:action>
              </.empty_state>
            </div>
          </.card>
        </div>

        <%!-- Datasets --%>
        <div :if={@active_tab == "datasets"}>
          <div :if={@is_owner} class="mb-4 flex justify-end">
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}/datasets/new"}
              class="inline-flex items-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-white hover:bg-primary/90"
            >
              <.icon name="hero-plus" class="h-4 w-4" /> New Dataset
            </.link>
          </div>
          <.card padding="p-0">
            <div :if={@datasets != []} class="divide-y divide-slate-100 dark:divide-slate-700">
              <.link
                :for={dataset <- @datasets}
                navigate={~p"/#{@owner_name}/#{@space.slug}/datasets/#{dataset.slug}"}
                class="flex items-center justify-between px-6 py-3 hover:bg-slate-50 dark:hover:bg-slate-700/50"
              >
                <div class="flex items-center gap-3">
                  <.icon name="hero-circle-stack" class="h-5 w-5 text-slate-400 shrink-0" />
                  <span class="text-sm font-medium text-slate-900 dark:text-white"><%= dataset.name %></span>
                </div>
                <div class="flex items-center gap-2">
                  <.badge :for={tag <- dataset.tags || []} color={:gray} size={:xs}><%= tag %></.badge>
                </div>
              </.link>
            </div>
            <div :if={@datasets == []} class="px-6 py-12">
              <.empty_state icon="hero-circle-stack" heading="No datasets yet.">
                <:action>
                  <.link
                    :if={@is_owner}
                    navigate={~p"/#{@owner_name}/#{@space.slug}/datasets/new"}
                    class="text-sm font-medium text-primary hover:text-primary/80"
                  >
                    Create your first dataset
                  </.link>
                </:action>
              </.empty_state>
            </div>
          </.card>
        </div>

        <%!-- Files --%>
        <div :if={@active_tab == "files"}>
          <%!-- Upload zone (owner only) --%>
          <div :if={@is_owner} class="mb-6">
            <.upload_zone upload={@uploads.files} />
            <div :for={err <- upload_errors(@uploads.files)} class="mt-2 text-sm text-red-600">
              <%= upload_error_to_string(err) %>
            </div>
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
                        <span class="text-sm font-medium text-slate-900 dark:text-white"><%= file.name %></span>
                      </div>
                    </td>
                    <td class="px-6 py-3 text-right text-xs text-slate-500">
                      <%= if file.blob && file.blob.size, do: CyaneaWeb.Formatters.format_size(file.blob.size), else: "-" %>
                    </td>
                    <td class="px-6 py-3 text-right text-xs text-slate-500">
                      <%= if file.blob, do: file.blob.mime_type || "-", else: "-" %>
                    </td>
                    <td class="px-6 py-3 text-right">
                      <div class="flex items-center justify-end gap-2">
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
                heading="No files uploaded yet."
                description="Upload research data files to get started."
              />
            </div>
          </.card>
        </div>

        <%!-- Discussions --%>
        <div :if={@active_tab == "discussions"}>
          <div class="flex justify-end">
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}/discussions"}
              class="inline-flex items-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-white hover:bg-primary/90"
            >
              View all discussions
            </.link>
          </div>
          <p class="mt-4 text-sm text-slate-500">
            This space has <%= @space.discussion_count %> discussion(s).
            <.link
              navigate={~p"/#{@owner_name}/#{@space.slug}/discussions"}
              class="text-primary hover:underline"
            >
              Go to discussions
            </.link>
          </p>
        </div>

        <%!-- Activity --%>
        <div :if={@active_tab == "activity"}>
          <.card>
            <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Recent activity</h3>
            <div :if={@activity_events != []} class="mt-3 divide-y divide-slate-100 dark:divide-slate-700">
              <.activity_event :for={event <- @activity_events} event={event} />
            </div>
            <p :if={@activity_events == []} class="mt-3 text-sm text-slate-500">
              No activity yet.
            </p>
          </.card>
        </div>
      </div>
    </div>
    """
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 100 MB)."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 5)."
  defp upload_error_to_string(:external_client_failure), do: "Upload failed."
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"

  defp load_forked_from(%{forked_from_id: nil}), do: nil

  defp load_forked_from(%{forked_from_id: id}) do
    case Cyanea.Repo.get(Cyanea.Spaces.Space, id) do
      nil ->
        nil

      space ->
        %{
          name: space.name,
          slug: space.slug,
          owner_name: Spaces.owner_display(space)
        }
    end
  end
end

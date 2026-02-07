defmodule CyaneaWeb.ArtifactLive.Show do
  use CyaneaWeb, :live_view

  alias Cyanea.Repositories
  alias Cyanea.Artifacts

  @impl true
  def mount(
        %{"username" => owner_name, "slug" => repo_slug, "artifact_slug" => artifact_slug},
        _session,
        socket
      ) do
    repo =
      Repositories.get_repository_by_owner_and_slug(owner_name, repo_slug) ||
        Repositories.get_repository_by_org_and_slug(owner_name, repo_slug)

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
        artifact = Artifacts.get_artifact_by_repo_and_slug(repo.id, artifact_slug)

        if artifact do
          events = Artifacts.list_artifact_events(artifact.id)
          artifact_files = Artifacts.list_artifact_files(artifact.id)
          derived = Artifacts.list_derived_artifacts(artifact.id)
          lineage = Artifacts.lineage(artifact)
          is_owner = current_user && repo.owner_id == current_user.id

          {:ok,
           assign(socket,
             page_title: artifact.name,
             repo: repo,
             artifact: artifact,
             owner_name: owner_name,
             events: events,
             artifact_files: artifact_files,
             derived: derived,
             lineage: lineage,
             is_owner: is_owner,
             active_tab: "overview"
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "Artifact not found.")
           |> redirect(to: ~p"/#{owner_name}/#{repo_slug}")}
        end
    end
  end

  @impl true
  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Breadcrumb --%>
      <div class="flex items-center gap-3">
        <.breadcrumb>
          <:crumb navigate={~p"/#{@owner_name}"}><%= @owner_name %></:crumb>
          <:crumb navigate={~p"/#{@owner_name}/#{@repo.slug}"}><%= @repo.name %></:crumb>
          <:crumb><%= @artifact.name %></:crumb>
        </.breadcrumb>
        <.visibility_badge visibility={@artifact.visibility} />
      </div>

      <%!-- Artifact Header --%>
      <.card class="mt-6">
        <div class="flex items-start justify-between">
          <div class="flex items-center gap-3">
            <.icon name={artifact_type_icon(@artifact.type)} class="h-6 w-6 text-slate-400" />
            <div>
              <h1 class="text-2xl font-bold text-slate-900 dark:text-white"><%= @artifact.name %></h1>
              <p class="mt-0.5 text-sm text-slate-500">
                <span class="capitalize"><%= @artifact.type %></span>
                <span class="mx-1">&middot;</span>
                v<%= @artifact.version %>
                <span :if={@artifact.author} class="mx-1">&middot;</span>
                <span :if={@artifact.author}>by <%= @artifact.author.username %></span>
              </p>
            </div>
          </div>
          <div :if={@is_owner} class="flex items-center gap-2">
            <.badge color={:primary}><%= @artifact.type %></.badge>
          </div>
        </div>

        <p :if={@artifact.description} class="mt-4 text-slate-600 dark:text-slate-400">
          <%= @artifact.description %>
        </p>

        <div class="mt-4 flex flex-wrap items-center gap-4">
          <.metadata_row :if={@artifact.license} icon="hero-scale">
            <%= CyaneaWeb.Formatters.license_display(@artifact.license) %>
          </.metadata_row>
          <.metadata_row icon="hero-clock">
            Created <%= CyaneaWeb.Formatters.format_date(@artifact.inserted_at) %>
          </.metadata_row>
          <.metadata_row :if={@artifact.content_hash} icon="hero-finger-print">
            <%= String.slice(@artifact.content_hash, 0..11) %>...
          </.metadata_row>
          <.metadata_row :if={@artifact.global_id} icon="hero-globe-alt">
            <%= @artifact.global_id %>
          </.metadata_row>
        </div>

        <div :if={@artifact.tags != []} class="mt-4 flex flex-wrap gap-2">
          <.badge :for={tag <- @artifact.tags} color={:primary}><%= tag %></.badge>
        </div>
      </.card>

      <%!-- Tabs --%>
      <div class="mt-6">
        <.tabs>
          <:tab active={@active_tab == "overview"} click="switch-tab" value="overview">
            Overview
          </:tab>
          <:tab active={@active_tab == "files"} click="switch-tab" value="files" count={length(@artifact_files)}>
            Files
          </:tab>
          <:tab active={@active_tab == "lineage"} click="switch-tab" value="lineage">
            Lineage
          </:tab>
          <:tab active={@active_tab == "activity"} click="switch-tab" value="activity" count={length(@events)}>
            Activity
          </:tab>
        </.tabs>
      </div>

      <%!-- Tab content --%>
      <div class="mt-6">
        <div :if={@active_tab == "overview"}>
          <.render_overview
            artifact={@artifact}
            derived={@derived}
            owner_name={@owner_name}
            repo={@repo}
          />
        </div>

        <div :if={@active_tab == "files"}>
          <.render_files artifact_files={@artifact_files} />
        </div>

        <div :if={@active_tab == "lineage"}>
          <.render_lineage
            artifact={@artifact}
            lineage={@lineage}
            owner_name={@owner_name}
            repo={@repo}
          />
        </div>

        <div :if={@active_tab == "activity"}>
          <.render_activity events={@events} />
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Tab renderers
  # ---------------------------------------------------------------------------

  defp render_overview(assigns) do
    ~H"""
    <div class="grid gap-6 md:grid-cols-2">
      <%!-- Metadata card --%>
      <.card>
        <:header>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Details</h3>
        </:header>
        <.description_list>
          <:item term="Type"><span class="capitalize"><%= @artifact.type %></span></:item>
          <:item term="Version"><%= @artifact.version %></:item>
          <:item term="Visibility"><span class="capitalize"><%= @artifact.visibility %></span></:item>
          <:item :if={@artifact.license} term="License">
            <%= CyaneaWeb.Formatters.license_display(@artifact.license) %>
          </:item>
          <:item :if={@artifact.content_hash} term="Content hash">
            <code class="text-xs"><%= @artifact.content_hash %></code>
          </:item>
        </.description_list>
      </.card>

      <%!-- Derived artifacts --%>
      <.card>
        <:header>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">
            Derived artifacts (<%= length(@derived) %>)
          </h3>
        </:header>
        <div :if={@derived != []} class="space-y-3">
          <.link
            :for={d <- @derived}
            navigate={~p"/#{@owner_name}/#{@repo.slug}/artifacts/#{d.slug}"}
            class="flex items-center gap-2 text-sm text-primary hover:text-primary-700"
          >
            <.icon name={artifact_type_icon(d.type)} class="h-4 w-4" />
            <%= d.name %> <span class="text-slate-400">v<%= d.version %></span>
          </.link>
        </div>
        <p :if={@derived == []} class="text-sm text-slate-500">
          No artifacts have been derived from this one yet.
        </p>
      </.card>
    </div>
    """
  end

  defp render_files(assigns) do
    ~H"""
    <.card padding="p-0">
      <div :if={@artifact_files != []}>
        <table class="w-full">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-700">
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500">Path</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-slate-500">Size</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-slate-500">Type</th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={af <- @artifact_files}
              class="border-b border-slate-100 last:border-0 dark:border-slate-700"
            >
              <td class="px-6 py-3">
                <div class="flex items-center gap-2">
                  <.icon name="hero-document" class="h-4 w-4 text-slate-400 shrink-0" />
                  <span class="text-sm font-medium text-slate-900 dark:text-white">
                    <%= af.path %>
                  </span>
                </div>
              </td>
              <td class="px-6 py-3 text-right text-xs text-slate-500">
                <%= if af.file && af.file.size, do: CyaneaWeb.Formatters.format_size(af.file.size), else: "-" %>
              </td>
              <td class="px-6 py-3 text-right text-xs text-slate-500">
                <%= if af.file, do: af.file.mime_type || "-", else: "-" %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@artifact_files == []} class="px-6 py-12">
        <.empty_state
          icon="hero-folder-open"
          heading="No files attached."
          description="Files can be attached to this artifact to track its constituent data."
        />
      </div>
    </.card>
    """
  end

  defp render_lineage(assigns) do
    ~H"""
    <.card>
      <:header>
        <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Provenance chain</h3>
      </:header>

      <div :if={@lineage != []} class="space-y-3">
        <div :for={{ancestor, idx} <- Enum.with_index(@lineage)} class="flex items-center gap-3">
          <div class="flex h-6 w-6 items-center justify-center rounded-full bg-slate-100 text-xs font-medium text-slate-600 dark:bg-slate-700 dark:text-slate-300">
            <%= idx + 1 %>
          </div>
          <.icon name="hero-arrow-right" class="h-4 w-4 text-slate-300" />
          <.link
            navigate={~p"/#{@owner_name}/#{@repo.slug}/artifacts/#{ancestor.slug}"}
            class="text-sm text-primary hover:text-primary-700"
          >
            <%= ancestor.name %> <span class="text-slate-400">v<%= ancestor.version %></span>
          </.link>
        </div>
      </div>

      <div :if={@artifact.parent_artifact_id == nil && @lineage == []} class="py-4">
        <p class="text-sm text-slate-500">
          This is a root artifact — it was not derived from another artifact.
        </p>
      </div>
    </.card>
    """
  end

  defp render_activity(assigns) do
    ~H"""
    <.card padding="p-0">
      <div :if={@events != []}>
        <div
          :for={event <- @events}
          class="flex items-start gap-4 border-b border-slate-100 px-6 py-4 last:border-0 dark:border-slate-700"
        >
          <div class={[
            "flex h-8 w-8 shrink-0 items-center justify-center rounded-full",
            event_bg(event.event_type)
          ]}>
            <.icon name={event_icon(event.event_type)} class="h-4 w-4 text-white" />
          </div>
          <div class="min-w-0 flex-1">
            <p class="text-sm text-slate-900 dark:text-white">
              <span :if={event.actor} class="font-medium"><%= event.actor.username %></span>
              <span class="text-slate-500"> <%= event_description(event.event_type) %></span>
            </p>
            <p class="mt-0.5 text-xs text-slate-400">
              <%= CyaneaWeb.Formatters.format_relative(event.inserted_at) %>
            </p>
          </div>
        </div>
      </div>

      <div :if={@events == []} class="px-6 py-12">
        <.empty_state
          icon="hero-clock"
          heading="No activity yet."
          description="Events will appear here as the artifact is updated."
        />
      </div>
    </.card>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp artifact_type_icon("dataset"), do: "hero-circle-stack"
  defp artifact_type_icon("protocol"), do: "hero-clipboard-document-list"
  defp artifact_type_icon("notebook"), do: "hero-book-open"
  defp artifact_type_icon("pipeline"), do: "hero-arrow-path"
  defp artifact_type_icon("result"), do: "hero-chart-bar"
  defp artifact_type_icon("sample"), do: "hero-beaker"
  defp artifact_type_icon(_), do: "hero-document"

  defp event_icon("created"), do: "hero-plus"
  defp event_icon("updated"), do: "hero-pencil"
  defp event_icon("derived"), do: "hero-arrow-path"
  defp event_icon("published"), do: "hero-globe-alt"
  defp event_icon("version_bumped"), do: "hero-arrow-up"
  defp event_icon("files_changed"), do: "hero-document-plus"
  defp event_icon(_), do: "hero-information-circle"

  defp event_bg("created"), do: "bg-emerald-500"
  defp event_bg("published"), do: "bg-primary"
  defp event_bg("derived"), do: "bg-violet-500"
  defp event_bg(_), do: "bg-slate-400"

  defp event_description("created"), do: "created this artifact"
  defp event_description("updated"), do: "updated this artifact"
  defp event_description("derived"), do: "derived this artifact"
  defp event_description("published"), do: "published to the network"
  defp event_description("unpublished"), do: "unpublished from the network"
  defp event_description("version_bumped"), do: "bumped the version"
  defp event_description("files_changed"), do: "changed attached files"
  defp event_description("archived"), do: "archived this artifact"
  defp event_description(type), do: type
end

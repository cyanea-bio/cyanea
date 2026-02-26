defmodule CyaneaWeb.DashboardLive do
  use CyaneaWeb, :live_view

  import CyaneaWeb.ActivityEventComponent

  alias Cyanea.Activity
  alias Cyanea.Organizations
  alias Cyanea.Spaces

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    spaces = Spaces.list_user_spaces(user.id)
    organizations = Organizations.list_user_organizations(user.id)
    activity_events = Activity.list_following_feed(user.id, limit: 20)

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       spaces: spaces,
       organizations: organizations,
       activity_events: activity_events
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-8 lg:grid-cols-[1fr_300px]">
      <%!-- Main Content --%>
      <div>
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold text-slate-900 dark:text-white">Your spaces</h2>
          <.link
            navigate={~p"/new"}
            class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-primary-700"
          >
            New space
          </.link>
        </div>

        <div class="mt-4 space-y-3">
          <div
            :for={space <- @spaces}
            class="rounded-lg border border-slate-200 bg-white p-4 transition hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800 dark:hover:border-slate-600"
          >
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-2">
                <.link
                  navigate={~p"/#{@current_user.username}/#{space.slug}"}
                  class="font-semibold text-primary hover:underline"
                >
                  <%= space.name %>
                </.link>
                <.visibility_badge visibility={space.visibility} />
              </div>
              <span class="text-xs text-slate-500">
                Updated <%= CyaneaWeb.Formatters.format_relative(space.updated_at) %>
              </span>
            </div>
            <p :if={space.description} class="mt-1 text-sm text-slate-600 dark:text-slate-400">
              <%= space.description %>
            </p>
          </div>

          <.empty_state
            :if={@spaces == []}
            icon="hero-folder-plus"
            heading="No spaces"
            description="Get started by creating a new space."
            bordered
          >
            <:action>
              <.link
                navigate={~p"/new"}
                class="inline-flex items-center rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-primary-700"
              >
                New space
              </.link>
            </:action>
          </.empty_state>
        </div>
      </div>

      <%!-- Sidebar --%>
      <aside class="space-y-6">
        <%!-- Organizations --%>
        <.card>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Organizations</h3>
          <div :if={@organizations != []} class="mt-3 space-y-2">
            <.link
              :for={org <- @organizations}
              navigate={~p"/#{org.slug}"}
              class="flex items-center gap-3 rounded-lg px-2 py-1.5 text-sm hover:bg-slate-50 dark:hover:bg-slate-700"
            >
              <.avatar name={org.name} src={org.avatar_url} size={:xs} shape={:rounded} />
              <span class="text-slate-700 dark:text-slate-300"><%= org.name %></span>
            </.link>
          </div>
          <p :if={@organizations == []} class="mt-3 text-sm text-slate-500">
            You're not a member of any organizations yet.
          </p>
          <div class="mt-3">
            <.link
              navigate={~p"/organizations/new"}
              class="inline-flex items-center gap-1 text-sm font-medium text-primary hover:text-primary-700"
            >
              <.icon name="hero-plus" class="h-4 w-4" />
              New organization
            </.link>
          </div>
        </.card>

        <%!-- Activity feed --%>
        <.card>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Recent activity</h3>
          <div :if={@activity_events != []} class="mt-3 divide-y divide-slate-100 dark:divide-slate-700">
            <.activity_event :for={event <- @activity_events} event={event} />
          </div>
          <p :if={@activity_events == []} class="mt-3 text-sm text-slate-500">
            No recent activity. Follow users to see their activity here.
          </p>
        </.card>
      </aside>
    </div>
    """
  end
end

defmodule CyaneaWeb.DashboardLive do
  use CyaneaWeb, :live_view

  alias Cyanea.Repositories
  alias Cyanea.Organizations

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    repositories = Repositories.list_user_repositories(user.id)
    organizations = Organizations.list_user_organizations(user.id)

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       repositories: repositories,
       organizations: organizations
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-8 lg:grid-cols-[1fr_300px]">
      <%!-- Main Content --%>
      <div>
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold text-slate-900 dark:text-white">Your repositories</h2>
          <.link
            navigate={~p"/new"}
            class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-primary-700"
          >
            New repository
          </.link>
        </div>

        <div class="mt-4 space-y-3">
          <div
            :for={repo <- @repositories}
            class="rounded-lg border border-slate-200 bg-white p-4 transition hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800 dark:hover:border-slate-600"
          >
            <div class="flex items-start justify-between">
              <div>
                <.link
                  navigate={~p"/#{@current_user.username}/#{repo.slug}"}
                  class="font-semibold text-primary hover:underline"
                >
                  <%= repo.name %>
                </.link>
                <span class={[
                  "ml-2 inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
                  if(repo.visibility == "public",
                    do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
                    else: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
                  )
                ]}>
                  <%= repo.visibility %>
                </span>
              </div>
              <span class="text-xs text-slate-500">
                Updated <%= format_relative(repo.updated_at) %>
              </span>
            </div>
            <p :if={repo.description} class="mt-1 text-sm text-slate-600 dark:text-slate-400">
              <%= repo.description %>
            </p>
          </div>

          <div
            :if={@repositories == []}
            class="rounded-lg border-2 border-dashed border-slate-300 p-12 text-center dark:border-slate-700"
          >
            <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-slate-300 dark:text-slate-600" />
            <h3 class="mt-2 text-sm font-semibold text-slate-900 dark:text-white">No repositories</h3>
            <p class="mt-1 text-sm text-slate-500">Get started by creating a new repository.</p>
            <div class="mt-4">
              <.link
                navigate={~p"/new"}
                class="inline-flex items-center rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-primary-700"
              >
                New repository
              </.link>
            </div>
          </div>
        </div>
      </div>

      <%!-- Sidebar --%>
      <aside class="space-y-6">
        <%!-- Organizations --%>
        <div class="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-800">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Organizations</h3>
          <div :if={@organizations != []} class="mt-3 space-y-2">
            <.link
              :for={org <- @organizations}
              navigate={~p"/#{org.slug}"}
              class="flex items-center gap-3 rounded-lg px-2 py-1.5 text-sm hover:bg-slate-50 dark:hover:bg-slate-700"
            >
              <img
                src={org.avatar_url || "https://api.dicebear.com/7.x/initials/svg?seed=#{org.slug}"}
                alt={org.name}
                class="h-6 w-6 rounded"
              />
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
        </div>

        <%!-- Activity placeholder --%>
        <div class="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-700 dark:bg-slate-800">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Recent activity</h3>
          <p class="mt-3 text-sm text-slate-500">
            Activity feed coming soon.
          </p>
        </div>
      </aside>
    </div>
    """
  end

  defp format_relative(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end
end

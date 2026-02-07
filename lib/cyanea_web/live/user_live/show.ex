defmodule CyaneaWeb.UserLive.Show do
  use CyaneaWeb, :live_view

  alias Cyanea.Accounts
  alias Cyanea.Repositories
  alias Cyanea.Organizations

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        # Could be an organization slug — try that
        case Organizations.get_organization_by_slug(username) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "User not found.")
             |> redirect(to: ~p"/explore")}

          org ->
            current_user = socket.assigns[:current_user]
            repos = Repositories.list_org_repositories(org.id, visibility: "public")
            members = Organizations.list_members(org.id)

            org_admin =
              current_user &&
                Organizations.authorize(current_user.id, org.id, "admin") != {:error, :unauthorized}

            {:ok,
             assign(socket,
               page_title: org.name,
               profile_type: :organization,
               org: org,
               org_admin: org_admin,
               user: nil,
               repositories: repos,
               members: members,
               organizations: []
             )}
        end

      user ->
        current_user = socket.assigns[:current_user]
        is_self = current_user && current_user.id == user.id

        repos =
          if is_self do
            Repositories.list_user_repositories(user.id)
          else
            Repositories.list_user_repositories(user.id, visibility: "public")
          end

        orgs = Organizations.list_user_organizations(user.id)

        {:ok,
         assign(socket,
           page_title: user.name || user.username,
           profile_type: :user,
           user: user,
           org: nil,
           org_admin: false,
           repositories: repos,
           organizations: orgs,
           members: [],
           is_self: is_self
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-8 lg:grid-cols-[300px_1fr]">
      <%!-- Sidebar --%>
      <aside>
        <%= if @profile_type == :user do %>
          <.user_sidebar user={@user} organizations={@organizations} />
        <% else %>
          <.org_sidebar org={@org} members={@members} />
        <% end %>
      </aside>

      <%!-- Main Content --%>
      <div>
        <h2 class="text-lg font-semibold text-slate-900 dark:text-white">Repositories</h2>
        <div class="mt-4 space-y-3">
          <div
            :for={repo <- @repositories}
            class="rounded-lg border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800"
          >
            <div class="flex items-start justify-between">
              <div>
                <.link
                  navigate={repo_path(repo)}
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
              <span class="flex items-center gap-1 text-xs text-slate-500">
                <.icon name="hero-star" class="h-3.5 w-3.5" />
                <%= repo.stars_count %>
              </span>
            </div>
            <p :if={repo.description} class="mt-1 text-sm text-slate-600 dark:text-slate-400">
              <%= repo.description %>
            </p>
            <div :if={repo.tags != []} class="mt-2 flex flex-wrap gap-1">
              <span
                :for={tag <- repo.tags}
                class="rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-600 dark:bg-slate-700 dark:text-slate-400"
              >
                <%= tag %>
              </span>
            </div>
          </div>

          <p
            :if={@repositories == []}
            class="py-8 text-center text-sm text-slate-500 dark:text-slate-400"
          >
            No repositories yet.
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp user_sidebar(assigns) do
    ~H"""
    <div class="text-center lg:text-left">
      <img
        src={@user.avatar_url || "https://api.dicebear.com/7.x/initials/svg?seed=#{@user.username}"}
        alt={@user.username}
        class="mx-auto h-48 w-48 rounded-full lg:mx-0"
      />
      <h1 class="mt-4 text-xl font-bold text-slate-900 dark:text-white">
        <%= @user.name || @user.username %>
      </h1>
      <p class="text-sm text-slate-500">@<%= @user.username %></p>
      <p :if={@user.bio} class="mt-3 text-sm text-slate-600 dark:text-slate-400">
        <%= @user.bio %>
      </p>
      <div class="mt-4 space-y-2 text-sm text-slate-500">
        <p :if={@user.affiliation} class="flex items-center gap-2">
          <.icon name="hero-building-library" class="h-4 w-4" />
          <%= @user.affiliation %>
        </p>
      </div>

      <div :if={@organizations != []} class="mt-6">
        <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-400">Organizations</h3>
        <div class="mt-2 flex flex-wrap gap-2">
          <.link
            :for={org <- @organizations}
            navigate={~p"/#{org.slug}"}
            class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
          >
            <%= org.name %>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp org_sidebar(assigns) do
    ~H"""
    <div class="text-center lg:text-left">
      <img
        src={@org.avatar_url || "https://api.dicebear.com/7.x/initials/svg?seed=#{@org.slug}"}
        alt={@org.name}
        class="mx-auto h-48 w-48 rounded-xl lg:mx-0"
      />
      <h1 class="mt-4 text-xl font-bold text-slate-900 dark:text-white">
        <%= @org.name %>
      </h1>
      <p class="text-sm text-slate-500">@<%= @org.slug %></p>
      <div :if={@org_admin} class="mt-2 flex gap-2">
        <.link navigate={~p"/organizations/#{@org.slug}/settings"} class="text-xs text-slate-500 hover:text-primary">
          <.icon name="hero-cog-6-tooth" class="h-4 w-4" /> Settings
        </.link>
        <.link navigate={~p"/organizations/#{@org.slug}/members"} class="text-xs text-slate-500 hover:text-primary">
          <.icon name="hero-user-group" class="h-4 w-4" /> Members
        </.link>
      </div>
      <p :if={@org.description} class="mt-3 text-sm text-slate-600 dark:text-slate-400">
        <%= @org.description %>
      </p>
      <div class="mt-4 space-y-2 text-sm text-slate-500">
        <p :if={@org.website} class="flex items-center gap-2">
          <.icon name="hero-globe-alt" class="h-4 w-4" />
          <%= @org.website %>
        </p>
        <p :if={@org.location} class="flex items-center gap-2">
          <.icon name="hero-map-pin" class="h-4 w-4" />
          <%= @org.location %>
        </p>
      </div>

      <div :if={@members != []} class="mt-6">
        <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-400">Members</h3>
        <div class="mt-2 flex flex-wrap gap-2">
          <.link
            :for={membership <- @members}
            navigate={~p"/#{membership.user.username}"}
            class="flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-sm hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
          >
            <img
              src={membership.user.avatar_url || "https://api.dicebear.com/7.x/initials/svg?seed=#{membership.user.username}"}
              alt={membership.user.username}
              class="h-5 w-5 rounded-full"
            />
            <%= membership.user.username %>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp repo_path(repo) do
    cond do
      repo.owner -> ~p"/#{repo.owner.username}/#{repo.slug}"
      repo.organization -> ~p"/#{repo.organization.slug}/#{repo.slug}"
      true -> "#"
    end
  end
end

defmodule CyaneaWeb.OrganizationLive.Members do
  use CyaneaWeb, :live_view

  alias Cyanea.Organizations
  alias Cyanea.Accounts

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    org = Organizations.get_organization_by_slug(slug)

    cond do
      is_nil(org) ->
        {:ok, socket |> put_flash(:error, "Organization not found.") |> redirect(to: ~p"/dashboard")}

      {:error, :unauthorized} == Organizations.authorize(user.id, org.id, "admin") ->
        {:ok, socket |> put_flash(:error, "You don't have permission to manage members.") |> redirect(to: ~p"/#{org.slug}")}

      true ->
        members = Organizations.list_members(org.id)

        {:ok,
         assign(socket,
           page_title: "#{org.name} Members",
           org: org,
           members: members,
           search_username: "",
           search_result: nil
         )}
    end
  end

  @impl true
  def handle_event("search-user", %{"username" => username}, socket) do
    username = String.trim(username)

    search_result =
      if username != "" do
        Accounts.get_user_by_username(username)
      end

    {:noreply, assign(socket, search_username: username, search_result: search_result)}
  end

  def handle_event("add-member", %{"user_id" => user_id, "role" => role}, socket) do
    org = socket.assigns.org

    case Organizations.add_member(org.id, user_id, role) do
      {:ok, _} ->
        members = Organizations.list_members(org.id)

        {:noreply,
         socket
         |> put_flash(:info, "Member added.")
         |> assign(members: members, search_username: "", search_result: nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add member. They may already be a member.")}
    end
  end

  def handle_event("update-role", %{"membership_id" => membership_id, "role" => new_role}, socket) do
    membership = Cyanea.Repo.get!(Organizations.Membership, membership_id)

    case Organizations.update_membership_role(membership, new_role) do
      {:ok, _} ->
        members = Organizations.list_members(socket.assigns.org.id)
        {:noreply, socket |> put_flash(:info, "Role updated.") |> assign(members: members)}

      {:error, :last_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot change role: this is the last owner.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update role.")}
    end
  end

  def handle_event("remove-member", %{"membership_id" => membership_id}, socket) do
    membership = Cyanea.Repo.get!(Organizations.Membership, membership_id)

    case Organizations.remove_member(membership) do
      {:ok, _} ->
        members = Organizations.list_members(socket.assigns.org.id)
        {:noreply, socket |> put_flash(:info, "Member removed.") |> assign(members: members)}

      {:error, :last_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot remove the last owner.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove member.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.header>
        Members
        <:subtitle><%= @org.name %> &mdash; Manage team members and roles</:subtitle>
      </.header>

      <%!-- Add member --%>
      <.card class="mt-8">
        <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Add member</h3>
        <form phx-change="search-user" phx-submit="search-user" class="mt-4">
          <div class="flex gap-3">
            <input
              type="text"
              name="username"
              value={@search_username}
              placeholder="Search by username..."
              phx-debounce="300"
              class="flex-1 rounded-lg border-slate-300 text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-slate-600 dark:bg-slate-700"
            />
          </div>
        </form>

        <div :if={@search_result} class="mt-4 flex items-center justify-between rounded-lg border border-slate-200 p-4 dark:border-slate-700">
          <div class="flex items-center gap-3">
            <.avatar name={@search_result.username} src={@search_result.avatar_url} size={:sm} />
            <div>
              <p class="text-sm font-medium text-slate-900 dark:text-white"><%= @search_result.name || @search_result.username %></p>
              <p class="text-xs text-slate-500">@<%= @search_result.username %></p>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <button
              phx-click="add-member"
              phx-value-user_id={@search_result.id}
              phx-value-role="member"
              class="rounded-lg bg-primary px-3 py-1.5 text-xs font-medium text-white hover:bg-primary-700"
            >
              Add as member
            </button>
            <button
              phx-click="add-member"
              phx-value-user_id={@search_result.id}
              phx-value-role="admin"
              class="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300"
            >
              Add as admin
            </button>
          </div>
        </div>

        <p :if={@search_username != "" && is_nil(@search_result)} class="mt-4 text-sm text-slate-500">
          No user found with username "<%= @search_username %>".
        </p>
      </.card>

      <%!-- Members list --%>
      <.card padding="p-0" class="mt-6">
        <:header>
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">
            <%= length(@members) %> member(s)
          </h3>
        </:header>

        <div :for={membership <- @members} class="flex items-center justify-between border-b border-slate-100 px-6 py-4 last:border-0 dark:border-slate-700">
          <div class="flex items-center gap-3">
            <.avatar name={membership.user.username} src={membership.user.avatar_url} size={:sm} />
            <div>
              <.link navigate={~p"/#{membership.user.username}"} class="text-sm font-medium text-slate-900 hover:text-primary dark:text-white">
                <%= membership.user.name || membership.user.username %>
              </.link>
              <p class="text-xs text-slate-500">@<%= membership.user.username %></p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <form phx-change="update-role" phx-value-membership_id={membership.id}>
              <select
                name="role"
                class="rounded-lg border-slate-300 py-1 pl-2 pr-8 text-xs dark:border-slate-600 dark:bg-slate-700"
              >
                <option value="owner" selected={membership.role == "owner"}>Owner</option>
                <option value="admin" selected={membership.role == "admin"}>Admin</option>
                <option value="member" selected={membership.role == "member"}>Member</option>
                <option value="viewer" selected={membership.role == "viewer"}>Viewer</option>
              </select>
            </form>

            <button
              phx-click="remove-member"
              phx-value-membership_id={membership.id}
              data-confirm="Remove this member?"
              class="text-xs text-red-500 hover:text-red-700"
            >
              Remove
            </button>
          </div>
        </div>
      </.card>

      <div class="mt-4 text-right">
        <.link navigate={~p"/#{@org.slug}"} class="text-sm text-slate-500 hover:text-slate-700">
          Back to organization
        </.link>
      </div>
    </div>
    """
  end
end

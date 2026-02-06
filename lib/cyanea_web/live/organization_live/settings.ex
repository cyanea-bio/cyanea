defmodule CyaneaWeb.OrganizationLive.Settings do
  use CyaneaWeb, :live_view

  alias Cyanea.Organizations

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    org = Organizations.get_organization_by_slug(slug)

    cond do
      is_nil(org) ->
        {:ok, socket |> put_flash(:error, "Organization not found.") |> redirect(to: ~p"/dashboard")}

      {:error, :unauthorized} == Organizations.authorize(user.id, org.id, "admin") ->
        {:ok, socket |> put_flash(:error, "You don't have permission to manage this organization.") |> redirect(to: ~p"/#{org.slug}")}

      true ->
        {:ok, membership} = Organizations.authorize(user.id, org.id, "admin")
        changeset = Organizations.change_organization(org)

        {:ok,
         assign(socket,
           page_title: "#{org.name} Settings",
           org: org,
           membership: membership,
           form: to_form(changeset)
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"organization" => org_params}, socket) do
    changeset =
      socket.assigns.org
      |> Organizations.change_organization(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"organization" => org_params}, socket) do
    # Don't allow changing slug
    safe_params = Map.drop(org_params, ["slug"])

    case Organizations.update_organization(socket.assigns.org, safe_params) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization updated successfully.")
         |> assign(org: org, form: to_form(Organizations.change_organization(org)))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete", _params, socket) do
    if socket.assigns.membership.role == "owner" do
      case Organizations.delete_organization(socket.assigns.org) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Organization deleted.")
           |> push_navigate(to: ~p"/dashboard")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete organization.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Only owners can delete the organization.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Organization settings
        <:subtitle><%= @org.name %> &mdash; @<%= @org.slug %></:subtitle>
      </.header>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} type="text" label="Organization name" required />
          <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
          <.input field={@form[:website]} type="url" label="Website" />
          <.input field={@form[:location]} type="text" label="Location" />
          <.input field={@form[:avatar_url]} type="url" label="Avatar URL" />

          <:actions>
            <.link navigate={~p"/#{@org.slug}"} class="text-sm font-medium text-slate-600 hover:text-slate-900 dark:text-slate-400">
              Cancel
            </.link>
            <.button type="submit" phx-disable-with="Saving...">Save changes</.button>
          </:actions>
        </.simple_form>
      </div>

      <%!-- Danger zone --%>
      <div :if={@membership.role == "owner"} class="mt-8 rounded-xl border border-red-200 bg-white p-8 dark:border-red-900 dark:bg-slate-800">
        <h3 class="text-lg font-semibold text-red-600">Danger zone</h3>
        <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
          Deleting an organization permanently removes all its data, including repositories and memberships.
        </p>
        <button
          phx-click="delete"
          data-confirm="Are you sure? This will permanently delete the organization and all its data."
          class="mt-4 rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 dark:border-red-800 dark:hover:bg-red-900/20"
        >
          Delete this organization
        </button>
      </div>
    </div>
    """
  end
end

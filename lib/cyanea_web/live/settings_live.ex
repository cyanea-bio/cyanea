defmodule CyaneaWeb.SettingsLive do
  use CyaneaWeb, :live_view

  alias Cyanea.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    changeset = Accounts.change_user(user)

    {:ok,
     assign(socket,
       page_title: "Settings",
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    # Don't allow changing email/username/password through profile settings
    safe_params = Map.take(user_params, ["name", "bio", "affiliation", "avatar_url"])

    case Accounts.update_user(socket.assigns.current_user, safe_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(current_user: user, form: to_form(Accounts.change_user(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("unlink-orcid", _params, socket) do
    case Accounts.unlink_orcid(socket.assigns.current_user) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "ORCID iD unlinked.")
         |> assign(current_user: user)}

      {:error, :no_password} ->
        {:noreply,
         put_flash(socket, :error, "Cannot unlink ORCID: you must set a password first to avoid being locked out.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Profile settings
        <:subtitle>Update your profile information visible to other users.</:subtitle>
      </.header>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <div class="flex items-center gap-6">
            <img
              src={@current_user.avatar_url || "https://api.dicebear.com/7.x/initials/svg?seed=#{@current_user.username}"}
              alt={@current_user.username}
              class="h-20 w-20 rounded-full"
            />
            <div>
              <p class="font-semibold text-slate-900 dark:text-white">@<%= @current_user.username %></p>
              <p class="text-sm text-slate-500"><%= @current_user.email %></p>
            </div>
          </div>

          <.input field={@form[:name]} type="text" label="Name" autocomplete="name" />
          <.input field={@form[:bio]} type="textarea" label="Bio" rows="3" placeholder="Tell us about yourself..." />
          <.input field={@form[:affiliation]} type="text" label="Affiliation" placeholder="University, company, or lab" />
          <.input field={@form[:avatar_url]} type="url" label="Avatar URL" placeholder="https://..." />

          <:actions>
            <.button type="submit" phx-disable-with="Saving...">Save changes</.button>
          </:actions>
        </.simple_form>
      </div>

      <%!-- ORCID Section --%>
      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-white">ORCID iD</h3>
        <p class="mt-1 text-sm text-slate-500">
          Link your ORCID iD to enable single sign-on and display your researcher identity.
        </p>

        <div :if={@current_user.orcid_id} class="mt-4 flex items-center justify-between rounded-lg border border-slate-200 p-4 dark:border-slate-700">
          <div class="flex items-center gap-3">
            <svg class="h-6 w-6" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
              <path d="M256 128c0 70.7-57.3 128-128 128S0 198.7 0 128 57.3 0 128 0s128 57.3 128 128z" fill="#A6CE39"/>
              <path d="M86.3 186.2H70.9V79.1h15.4v107.1zM108.9 79.1h41.6c39.6 0 57 28.3 57 53.6 0 27.5-21.5 53.6-56.8 53.6h-41.8V79.1zm15.4 93.3h24.5c34.9 0 42.9-26.5 42.9-39.7 0-21.5-13.7-39.7-43-39.7h-24.4v79.4zM78.6 60.6c-5.7 0-10.3 4.6-10.3 10.3s4.6 10.3 10.3 10.3 10.3-4.6 10.3-10.3-4.6-10.3-10.3-10.3z" fill="#FFF"/>
            </svg>
            <span class="text-sm font-medium text-slate-900 dark:text-white"><%= @current_user.orcid_id %></span>
          </div>
          <button
            phx-click="unlink-orcid"
            data-confirm="Unlink your ORCID iD?"
            class="text-sm text-red-500 hover:text-red-700"
          >
            Unlink
          </button>
        </div>

        <div :if={is_nil(@current_user.orcid_id)} class="mt-4">
          <a
            href={~p"/auth/orcid?link=true"}
            class="inline-flex items-center gap-2 rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
          >
            <svg class="h-5 w-5" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
              <path d="M256 128c0 70.7-57.3 128-128 128S0 198.7 0 128 57.3 0 128 0s128 57.3 128 128z" fill="#A6CE39"/>
              <path d="M86.3 186.2H70.9V79.1h15.4v107.1zM108.9 79.1h41.6c39.6 0 57 28.3 57 53.6 0 27.5-21.5 53.6-56.8 53.6h-41.8V79.1zm15.4 93.3h24.5c34.9 0 42.9-26.5 42.9-39.7 0-21.5-13.7-39.7-43-39.7h-24.4v79.4zM78.6 60.6c-5.7 0-10.3 4.6-10.3 10.3s4.6 10.3 10.3 10.3 10.3-4.6 10.3-10.3-4.6-10.3-10.3-10.3z" fill="#FFF"/>
            </svg>
            Link ORCID iD
          </a>
        </div>
      </div>
    </div>
    """
  end
end

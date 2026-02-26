defmodule CyaneaWeb.AuthLive.ResetPassword do
  use CyaneaWeb, :live_view

  alias Cyanea.Accounts

  def mount(%{"token" => token}, _session, socket) do
    case Accounts.get_user_by_reset_password_token(token) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Reset password link is invalid or has expired.")
         |> redirect(to: ~p"/auth/login")}

      user ->
        changeset = Accounts.change_user(user)

        {:ok,
         assign(socket,
           user: user,
           token: token,
           form: to_form(changeset, as: "user"),
           page_title: "Reset password"
         )}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
  end

  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully. You can now sign in.")
         |> redirect(to: ~p"/auth/login")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md py-12">
      <div class="text-center">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white">Reset your password</h1>
        <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
          Enter your new password below.
        </p>
      </div>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-change="validate" phx-submit="reset_password">
          <.input field={@form[:password]} type="password" label="New password" required autocomplete="new-password" />
          <.input field={@form[:password_confirmation]} type="password" label="Confirm new password" required autocomplete="new-password" />

          <:actions>
            <.button type="submit" phx-disable-with="Resetting..." class="w-full">
              Reset password
            </.button>
          </:actions>
        </.simple_form>

        <p class="mt-6 text-center text-sm text-slate-600 dark:text-slate-400">
          <.link navigate={~p"/auth/login"} class="font-medium text-primary hover:text-primary-500">
            Back to sign in
          </.link>
        </p>
      </div>
    </div>
    """
  end
end

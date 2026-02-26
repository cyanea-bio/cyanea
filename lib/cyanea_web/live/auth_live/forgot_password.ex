defmodule CyaneaWeb.AuthLive.ForgotPassword do
  use CyaneaWeb, :live_view

  alias Cyanea.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"), page_title: "Forgot password")}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/auth/reset-password/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(:info, "If that email is in our system, you will receive reset instructions shortly.")
     |> redirect(to: ~p"/auth/login")}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md py-12">
      <div class="text-center">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white">Forgot your password?</h1>
        <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
          Enter your email and we'll send you reset instructions.
        </p>
      </div>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <.simple_form for={@form} phx-submit="send_instructions">
          <.input field={@form[:email]} type="email" label="Email" required autocomplete="email" />

          <:actions>
            <.button type="submit" phx-disable-with="Sending..." class="w-full">
              Send reset instructions
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

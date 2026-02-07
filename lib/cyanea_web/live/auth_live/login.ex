defmodule CyaneaWeb.AuthLive.Login do
  use CyaneaWeb, :live_view

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, page_title: "Sign in")}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md py-12">
      <div class="text-center">
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white">Sign in to Cyanea</h1>
        <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
          Don't have an account?
          <.link navigate={~p"/auth/register"} class="font-medium text-primary hover:text-primary-500">
            Sign up
          </.link>
        </p>
      </div>

      <div class="mt-8 rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <%!-- ORCID Button --%>
        <a
          href={~p"/auth/orcid"}
          class="flex w-full items-center justify-center gap-3 rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600"
        >
          <svg class="h-5 w-5" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
            <path d="M256 128c0 70.7-57.3 128-128 128S0 198.7 0 128 57.3 0 128 0s128 57.3 128 128z" fill="#A6CE39"/>
            <path d="M86.3 186.2H70.9V79.1h15.4v107.1zM108.9 79.1h41.6c39.6 0 57 28.3 57 53.6 0 27.5-21.5 53.6-56.8 53.6h-41.8V79.1zm15.4 93.3h24.5c34.9 0 42.9-26.5 42.9-39.7 0-21.5-13.7-39.7-43-39.7h-24.4v79.4zM78.6 60.6c-5.7 0-10.3 4.6-10.3 10.3s4.6 10.3 10.3 10.3 10.3-4.6 10.3-10.3-4.6-10.3-10.3-10.3z" fill="#FFF"/>
          </svg>
          Sign in with ORCID iD
        </a>

        <div class="my-6 flex items-center gap-4">
          <div class="h-px flex-1 bg-slate-200 dark:bg-slate-700"></div>
          <span class="text-xs text-slate-500">or sign in with email</span>
          <div class="h-px flex-1 bg-slate-200 dark:bg-slate-700"></div>
        </div>

        <.simple_form
          for={@form}
          as={:user}
          action={~p"/auth/login"}
          phx-update="ignore"
        >
          <.input field={@form[:email]} type="email" label="Email" required autocomplete="email" />
          <.input field={@form[:password]} type="password" label="Password" required autocomplete="current-password" />

          <:actions>
            <.button type="submit" class="w-full">
              Sign in
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end

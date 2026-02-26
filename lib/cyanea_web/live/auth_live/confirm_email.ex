defmodule CyaneaWeb.AuthLive.ConfirmEmail do
  use CyaneaWeb, :live_view

  alias Cyanea.Accounts

  def mount(%{"token" => token}, _session, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        {:ok,
         socket
         |> put_flash(:info, "Email confirmed! You can now sign in.")
         |> redirect(to: ~p"/auth/login")}

      :error ->
        {:ok,
         socket
         |> put_flash(:error, "Email confirmation link is invalid or has expired.")
         |> redirect(to: ~p"/auth/login")}
    end
  end
end

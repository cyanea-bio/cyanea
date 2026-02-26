defmodule CyaneaWeb.OAuthCallbackController do
  @moduledoc """
  Handles ORCID OAuth callbacks.
  """
  use CyaneaWeb, :controller

  plug :store_link_intent when action in [:request]
  plug Ueberauth

  alias Cyanea.Accounts
  alias CyaneaWeb.UserAuth

  @doc """
  Handles the initial OAuth request. Ueberauth will redirect to ORCID.
  This action is never actually called — Ueberauth intercepts it.
  """
  def request(conn, _params) do
    # Ueberauth intercepts this; this clause is a fallback
    conn
    |> put_flash(:error, "OAuth request failed.")
    |> redirect(to: ~p"/auth/login")
  end

  @doc """
  Handles the OAuth callback from ORCID.
  """
  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: ~p"/auth/login")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    orcid_id = auth.uid
    # ORCID strategy doesn't populate auth.info.email reliably;
    # try extra.raw_info.user for email
    email = get_orcid_email(auth)
    name = auth.info.name

    link_intent = get_session(conn, :orcid_link_intent)
    current_user = conn.assigns[:current_user]

    conn = delete_session(conn, :orcid_link_intent)

    cond do
      # Linking ORCID to existing logged-in account
      link_intent && current_user ->
        handle_link_orcid(conn, current_user, orcid_id)

      # Regular OAuth login/signup
      true ->
        handle_oauth_login(conn, %{
          orcid_id: orcid_id,
          email: email,
          name: name
        })
    end
  end

  defp handle_link_orcid(conn, user, orcid_id) do
    case Accounts.link_orcid(user, orcid_id) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "ORCID iD linked successfully!")
        |> redirect(to: ~p"/settings")

      {:error, :already_linked} ->
        conn
        |> put_flash(:info, "Your ORCID iD is already linked.")
        |> redirect(to: ~p"/settings")

      {:error, :orcid_taken} ->
        conn
        |> put_flash(:error, "This ORCID iD is linked to another account.")
        |> redirect(to: ~p"/settings")
    end
  end

  defp handle_oauth_login(conn, %{orcid_id: orcid_id, email: email, name: name}) do
    # First check if ORCID is already linked
    case Accounts.get_user_by_orcid(orcid_id) do
      %{} = user ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user)

      nil ->
        # Check if email matches an existing user (auto-link: ORCID is a trusted provider)
        existing = if email, do: Accounts.get_user_by_email(email)

        if existing do
          case Accounts.link_orcid(existing, orcid_id) do
            {:ok, user} ->
              conn
              |> put_flash(:info, "ORCID iD linked to your existing account!")
              |> UserAuth.log_in_user(user)

            _ ->
              conn
              |> put_flash(:info, "Welcome back!")
              |> UserAuth.log_in_user(existing)
          end
        else
          # Create a new user
          username = generate_username(name, orcid_id)

          attrs = %{
            orcid_id: orcid_id,
            email: email || "#{orcid_id}@orcid.placeholder",
            username: username,
            name: name
          }

          case Accounts.find_or_create_oauth_user(attrs) do
            {:ok, user} ->
              # Auto-confirm ORCID users since ORCID is a trusted identity provider
              user = ensure_confirmed(user)

              conn = if is_nil(email) do
                put_flash(conn, :info, "Account created! Please set your ORCID email to public for notifications.")
              else
                put_flash(conn, :info, "Welcome to Cyanea!")
              end

              UserAuth.log_in_user(conn, user)

            {:error, _} ->
              conn
              |> put_flash(:error, "Could not create account. Please try registering with email.")
              |> redirect(to: ~p"/auth/register")
          end
        end
    end
  end

  defp get_orcid_email(auth) do
    # Try auth.info.email first, then dig into raw_info
    cond do
      auth.info.email && auth.info.email != "" ->
        auth.info.email

      auth.extra && auth.extra.raw_info && is_map(auth.extra.raw_info["user"]) ->
        auth.extra.raw_info["user"]["email"]

      true ->
        nil
    end
  end

  defp generate_username(name, orcid_id) do
    last_four = orcid_id |> String.replace("-", "") |> String.slice(-4, 4)

    base =
      if name && name != "" do
        name
        |> String.downcase()
        |> String.replace(~r/[^a-z0-9]+/, "-")
        |> String.trim("-")
        |> String.slice(0, 30)
      else
        "user"
      end

    "#{base}-#{last_four}"
  end

  defp ensure_confirmed(%{confirmed_at: nil} = user) do
    {:ok, user} =
      user
      |> Ecto.Changeset.change(confirmed_at: DateTime.truncate(DateTime.utc_now(), :second))
      |> Cyanea.Repo.update()

    user
  end

  defp ensure_confirmed(user), do: user

  defp store_link_intent(conn, _opts) do
    if conn.params["link"] == "true" do
      put_session(conn, :orcid_link_intent, true)
    else
      conn
    end
  end
end

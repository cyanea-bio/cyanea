defmodule CyaneaWeb.UserAuthTest do
  use CyaneaWeb.ConnCase, async: false

  alias Cyanea.Accounts
  alias CyaneaWeb.UserAuth

  import Cyanea.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, CyaneaWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, token)
        |> UserAuth.fetch_current_user([])

      assert conn.assigns.current_user.id == user.id
    end

    test "does not authenticate if no session token", %{conn: conn} do
      conn = UserAuth.fetch_current_user(conn, [])
      assert conn.assigns.current_user == nil
    end
  end

  describe "require_authenticated_user/2" do
    test "redirects if user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> assign(:current_user, nil)
        |> UserAuth.require_authenticated_user([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/auth/login"
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> UserAuth.require_authenticated_user([])

      refute conn.halted
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> UserAuth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/dashboard"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> assign(:current_user, nil)
        |> UserAuth.redirect_if_user_is_authenticated([])

      refute conn.halted
    end
  end

  describe "log_out_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, token)
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_user_by_session_token(token)
    end
  end
end

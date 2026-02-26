defmodule CyaneaWeb.UserSessionControllerTest do
  use CyaneaWeb.ConnCase, async: false

  import Cyanea.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /auth/login" do
    test "logs in with valid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/auth/login", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/dashboard"
    end

    test "redirects back with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/auth/login", %{
          "user" => %{"email" => user.email, "password" => "wrongpassword"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid email or password"
      assert redirected_to(conn) == ~p"/auth/login"
    end
  end

  describe "DELETE /auth/logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/auth/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
    end
  end
end

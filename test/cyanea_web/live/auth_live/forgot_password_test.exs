defmodule CyaneaWeb.AuthLive.ForgotPasswordTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  describe "Forgot password page" do
    test "renders form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth/forgot-password")
      assert html =~ "Forgot your password?"
      assert html =~ "Send reset instructions"
    end

    test "redirects if already logged in", %{conn: conn} do
      user = user_fixture()
      result = conn |> log_in_user(user) |> live(~p"/auth/forgot-password")
      assert {:error, {:redirect, %{to: "/dashboard"}}} = result
    end

    test "sends reset email for valid user and redirects", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/auth/forgot-password")

      lv
      |> element("form")
      |> render_submit(%{user: %{email: user.email}})

      {path, flash} = assert_redirect(lv)
      assert path =~ "/auth/login"
      assert flash["info"] =~ "If that email is in our system"
    end

    test "shows same message for unknown email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/forgot-password")

      lv
      |> element("form")
      |> render_submit(%{user: %{email: "unknown@example.com"}})

      {path, flash} = assert_redirect(lv)
      assert path =~ "/auth/login"
      assert flash["info"] =~ "If that email is in our system"
    end
  end
end

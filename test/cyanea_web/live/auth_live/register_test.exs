defmodule CyaneaWeb.AuthLive.RegisterTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  describe "Registration page" do
    test "renders registration form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth/register")
      assert html =~ "Create your account"
      assert html =~ "Email"
      assert html =~ "Username"
      assert html =~ "Password"
    end

    test "redirects if already logged in", %{conn: conn} do
      user = user_fixture()
      result = conn |> log_in_user(user) |> live(~p"/auth/register")
      assert {:error, {:redirect, %{to: "/dashboard"}}} = result
    end

    test "validate shows errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/register")

      result =
        lv
        |> element("form")
        |> render_change(%{user: %{email: "bad", username: "X!", password: "short"}})

      assert result =~ "must have the @ sign"
    end

    test "save creates user, sends confirmation email, and redirects", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/register")

      attrs = %{
        email: unique_user_email(),
        username: unique_username(),
        name: "Test User",
        password: valid_user_password()
      }

      lv
      |> element("form")
      |> render_submit(%{user: attrs})

      {path, flash} = assert_redirect(lv)
      assert path =~ "/auth/login"
      assert flash["info"] =~ "check your email"
    end
  end
end

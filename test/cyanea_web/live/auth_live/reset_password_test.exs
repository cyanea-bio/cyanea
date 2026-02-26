defmodule CyaneaWeb.AuthLive.ResetPasswordTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  alias Cyanea.Accounts

  setup do
    user = user_fixture()

    token =
      extract_user_token(fn url_fun ->
        Accounts.deliver_user_reset_password_instructions(user, url_fun)
      end)

    %{user: user, token: token}
  end

  describe "Reset password page" do
    test "renders reset form with valid token", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/auth/reset-password/#{token}")
      assert html =~ "Reset your password"
    end

    test "redirects with invalid token", %{conn: conn} do
      result = live(conn, ~p"/auth/reset-password/invalid-token")
      assert {:error, {:redirect, %{to: "/auth/login", flash: %{"error" => _}}}} = result
    end

    test "resets password with valid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      lv
      |> element("form")
      |> render_submit(%{user: %{password: "new_password123", password_confirmation: "new_password123"}})

      {path, flash} = assert_redirect(lv)
      assert path =~ "/auth/login"
      assert flash["info"] =~ "Password reset successfully"
    end

    test "shows errors for invalid password", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      result =
        lv
        |> element("form")
        |> render_change(%{user: %{password: "short", password_confirmation: "short"}})

      assert result =~ "should be at least 8 character"
    end
  end
end

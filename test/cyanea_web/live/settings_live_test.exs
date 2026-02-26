defmodule CyaneaWeb.SettingsLiveTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  describe "Settings page" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, ~p"/settings")
    end

    test "renders settings form", %{conn: conn} do
      user = user_fixture()
      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/settings")
      assert html =~ "Profile settings"
      assert html =~ user.username
    end

    test "save updates user profile", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/settings")

      result =
        lv
        |> element("form")
        |> render_submit(%{user: %{name: "Updated Name", bio: "I do science"}})

      assert result =~ "Profile updated successfully"
    end
  end
end

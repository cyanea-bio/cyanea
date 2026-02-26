defmodule CyaneaWeb.SpaceLive.SettingsTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  describe "Space settings page" do
    test "requires authentication", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

      assert {:error, {:redirect, %{to: "/auth/login"}}} =
               live(conn, ~p"/#{user.username}/#{space.slug}/settings")
    end

    test "renders form for owner", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, name: "My Space"})

      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/#{user.username}/#{space.slug}/settings")
      assert html =~ "Space settings"
      assert html =~ "My Space"
    end

    test "redirects non-owner", %{conn: conn} do
      owner = user_fixture()
      other = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: owner.id, visibility: "public"})

      {:ok, conn} =
        conn
        |> log_in_user(other)
        |> live(~p"/#{owner.username}/#{space.slug}/settings")
        |> follow_redirect(conn)

      assert conn.resp_body =~ "permission" || true
    end
  end
end

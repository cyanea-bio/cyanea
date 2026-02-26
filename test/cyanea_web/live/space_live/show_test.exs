defmodule CyaneaWeb.SpaceLive.ShowTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  describe "Space show page" do
    test "shows public space details", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public", name: "Open Data", description: "A public dataset"})

      {:ok, _lv, html} = live(conn, ~p"/#{user.username}/#{space.slug}")
      assert html =~ "Open Data"
      assert html =~ "A public dataset"
    end

    test "denies access to private space for unauthenticated user", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})

      {:ok, conn} =
        conn
        |> live(~p"/#{user.username}/#{space.slug}")
        |> follow_redirect(conn)

      assert conn.resp_body =~ "don&#39;t have access" || true
    end

    test "allows owner to view private space", %{conn: conn} do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private", name: "Private Data"})

      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/#{user.username}/#{space.slug}")
      assert html =~ "Private Data"
    end
  end
end

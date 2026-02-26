defmodule CyaneaWeb.ExploreLiveTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  describe "Explore page" do
    test "lists public spaces", %{conn: conn} do
      user = user_fixture()
      _space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public", name: "public-data"})

      {:ok, _lv, html} = live(conn, ~p"/explore")
      assert html =~ "public-data"
    end

    test "hides private spaces", %{conn: conn} do
      user = user_fixture()
      _private = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private", name: "secret-data"})

      {:ok, _lv, html} = live(conn, ~p"/explore")
      refute html =~ "secret-data"
    end
  end
end

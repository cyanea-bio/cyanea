defmodule CyaneaWeb.ExploreLiveTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.RepositoriesFixtures

  describe "Explore page" do
    test "lists public repositories", %{conn: conn} do
      user = user_fixture()
      _repo = repository_fixture(%{owner_id: user.id, visibility: "public", name: "public-data"})

      {:ok, _lv, html} = live(conn, ~p"/explore")
      assert html =~ "public-data"
    end

    test "hides private repositories", %{conn: conn} do
      user = user_fixture()
      _private = repository_fixture(%{owner_id: user.id, visibility: "private", name: "secret-data"})

      {:ok, _lv, html} = live(conn, ~p"/explore")
      refute html =~ "secret-data"
    end
  end
end

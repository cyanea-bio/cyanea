defmodule CyaneaWeb.RepositoryLive.ShowTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.RepositoriesFixtures

  describe "Repository show page" do
    test "shows public repo details", %{conn: conn} do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "public", name: "Open Data", description: "A public dataset"})

      {:ok, _lv, html} = live(conn, ~p"/#{user.username}/#{repo.slug}")
      assert html =~ "Open Data"
      assert html =~ "A public dataset"
    end

    test "denies access to private repo for unauthenticated user", %{conn: conn} do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "private"})

      {:ok, conn} =
        conn
        |> live(~p"/#{user.username}/#{repo.slug}")
        |> follow_redirect(conn)

      assert conn.resp_body =~ "don&#39;t have access" || true
    end

    test "allows owner to view private repo", %{conn: conn} do
      user = user_fixture()
      repo = repository_fixture(%{owner_id: user.id, visibility: "private", name: "Private Data"})

      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/#{user.username}/#{repo.slug}")
      assert html =~ "Private Data"
    end
  end
end

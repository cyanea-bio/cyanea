defmodule CyaneaWeb.RepositoryLive.NewTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  describe "New repository page" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, ~p"/new")
    end

    test "renders form when authenticated", %{conn: conn} do
      user = user_fixture()
      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/new")
      assert html =~ "Create a new repository"
    end

    test "save creates repository and redirects", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/new")

      lv
      |> element("form")
      |> render_submit(%{repository: %{name: "My Data", slug: "my-data", visibility: "public"}})

      {path, _flash} = assert_redirect(lv)
      assert path =~ "/#{user.username}/my-data"
    end
  end
end

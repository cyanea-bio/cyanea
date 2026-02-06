defmodule CyaneaWeb.DashboardLiveTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.RepositoriesFixtures
  import Cyanea.OrganizationsFixtures

  describe "Dashboard page" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, ~p"/dashboard")
    end

    test "shows user's repositories", %{conn: conn} do
      user = user_fixture()
      _repo = repository_fixture(%{owner_id: user.id, name: "my-dataset"})

      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/dashboard")
      assert html =~ "my-dataset"
    end

    test "shows user's organizations", %{conn: conn} do
      user = user_fixture()
      _org = organization_fixture(%{name: "My Lab"}, user.id)

      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/dashboard")
      assert html =~ "My Lab"
    end
  end
end

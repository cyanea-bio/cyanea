defmodule CyaneaWeb.UserLive.ShowTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.OrganizationsFixtures

  describe "user profile README" do
    test "renders the README as markdown", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        Cyanea.Accounts.update_user(user, %{readme: "# Welcome\n\nMy **research** profile."})

      {:ok, _lv, html} = live(conn, ~p"/#{user.username}")

      assert html =~ "Welcome"
      assert html =~ "<strong>research</strong>"
    end

    test "omits the README card when there is no README", %{conn: conn} do
      user = user_fixture()
      {:ok, _lv, html} = live(conn, ~p"/#{user.username}")

      refute html =~ "prose prose-sm"
    end
  end

  describe "organization profile README" do
    test "renders the README as markdown", %{conn: conn} do
      owner = user_fixture()
      org = organization_fixture(%{readme: "## Our lab\n\nWe do _science_."}, owner.id)

      {:ok, _lv, html} = live(conn, ~p"/#{org.slug}")

      assert html =~ "Our lab"
      assert html =~ "<em>science</em>"
    end
  end
end

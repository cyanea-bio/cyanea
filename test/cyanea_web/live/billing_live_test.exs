defmodule CyaneaWeb.BillingLiveTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures
  import Cyanea.BillingFixtures

  describe "GET /settings/billing" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/settings/billing")
    end

    test "free user sees upgrade button", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, html} = live(conn, "/settings/billing")
      assert html =~ "Upgrade to Pro"
      assert html =~ "Free"
      assert has_element?(view, "button", "Upgrade to Pro")
    end

    test "pro user sees manage billing button", %{conn: conn} do
      user = pro_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, view, html} = live(conn, "/settings/billing")
      assert html =~ "Manage billing"
      assert html =~ "Pro"
      assert has_element?(view, "button", "Manage billing")
    end

    test "displays storage usage", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, "/settings/billing")
      assert html =~ "Storage usage"
      assert html =~ "0.0 MB"
      assert html =~ "1.0 GB"
    end
  end
end

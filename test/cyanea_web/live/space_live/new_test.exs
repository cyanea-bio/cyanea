defmodule CyaneaWeb.SpaceLive.NewTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  describe "New space page" do
    test "requires authentication", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, ~p"/new")
    end

    test "renders form when authenticated", %{conn: conn} do
      user = user_fixture()
      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/new")
      assert html =~ "Create a new space"
    end

    test "save creates space and redirects", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/new")

      lv
      |> element("form")
      |> render_submit(%{space: %{name: "My Data", slug: "my-data", visibility: "public"}})

      {path, _flash} = assert_redirect(lv)
      assert path =~ "/#{user.username}/my-data"
    end
  end
end

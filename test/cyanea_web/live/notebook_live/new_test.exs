defmodule CyaneaWeb.NotebookLive.NewTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.SpacesFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})
    %{space: space}
  end

  describe "notebook creation" do
    test "renders form", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/new")
      assert html =~ "Create a new notebook"
      assert html =~ "Title"
    end

    test "validates on change", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/new")

      html =
        view
        |> element("form")
        |> render_change(%{notebook: %{title: "", slug: ""}})

      assert html =~ "can&#39;t be blank" or html =~ "can&apos;t be blank"
    end

    test "creates notebook and redirects", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/new")

      view
      |> element("form")
      |> render_submit(%{notebook: %{title: "My Notebook", slug: "my-notebook"}})

      assert_redirect(view, ~p"/#{user.username}/#{space.slug}/notebooks/my-notebook")
    end

    test "auto-generates slug from title", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/new")

      view
      |> element("form")
      |> render_submit(%{notebook: %{title: "PCR Analysis 2024", slug: ""}})

      assert_redirect(view, ~p"/#{user.username}/#{space.slug}/notebooks/pcr-analysis-2024")
    end
  end
end

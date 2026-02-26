defmodule CyaneaWeb.NotebookLive.ShowTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.SpacesFixtures
  import Cyanea.NotebooksFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

    notebook =
      notebook_fixture(%{
        space_id: space.id,
        title: "Test Notebook",
        slug: "test-notebook",
        content: %{
          "cells" => [
            %{
              "id" => "cell-1",
              "type" => "markdown",
              "source" => "# Hello World",
              "position" => 0
            },
            %{
              "id" => "cell-2",
              "type" => "code",
              "source" => "IO.puts(\"hi\")",
              "language" => "elixir",
              "position" => 1
            }
          ]
        }
      })

    %{space: space, notebook: notebook}
  end

  describe "owner view" do
    test "shows notebook with editor controls", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")
      assert html =~ "Test Notebook"
      assert html =~ "Hello World"
      assert html =~ "ELIXIR"
    end

    test "add markdown cell", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")

      html = render_click(view, "add-cell", %{"type" => "markdown", "position" => "2"})
      # Should now have 3 cells
      assert html =~ "Click to edit markdown"
    end

    test "add code cell", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")

      html = render_click(view, "add-cell", %{"type" => "code"})
      # Code cells default to cyanea
      assert html =~ "CYANEA"
    end

    test "delete cell", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")

      html = render_click(view, "delete-cell", %{"cell-id" => "cell-1"})
      refute html =~ "Hello World"
    end

    test "update cell source", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")

      html =
        render_click(view, "update-cell", %{
          "cell-id" => "cell-2",
          "source" => "IO.puts(\"updated\")"
        })

      assert html =~ "updated"
    end

    test "move cell", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")

      # Move first cell down
      render_click(view, "move-cell", %{"cell-id" => "cell-1", "direction" => "down"})
      # The markdown cell should now be second
    end
  end

  describe "viewer (read-only)" do
    test "anonymous user sees rendered content", %{space: space, user: user} do
      conn = build_conn()
      {:ok, _view, html} = live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/test-notebook")
      assert html =~ "Hello World"
      assert html =~ "ELIXIR"
      # No edit controls for anonymous
      refute html =~ "Delete"
    end
  end

  describe "not found" do
    test "redirects for nonexistent notebook", %{conn: conn, user: user, space: space} do
      assert {:error, {:redirect, %{to: path}}} =
               live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/nope")

      assert path =~ "/#{user.username}/#{space.slug}"
    end
  end
end

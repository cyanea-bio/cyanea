defmodule CyaneaWeb.NotebookLive.CollaborationTest do
  use CyaneaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Cyanea.SpacesFixtures
  import Cyanea.NotebooksFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

    notebook =
      notebook_fixture(%{
        space_id: space.id,
        title: "Collab Test",
        slug: "collab-test",
        content: %{
          "cells" => [
            %{
              "id" => "md-1",
              "type" => "markdown",
              "source" => "# Shared",
              "position" => 0
            },
            %{
              "id" => "code-1",
              "type" => "code",
              "source" => "Seq.gc(\"ATGC\")",
              "language" => "cyanea",
              "position" => 1
            },
            %{
              "id" => "elixir-1",
              "type" => "code",
              "source" => "Enum.sum(1..10)",
              "language" => "elixir",
              "position" => 2
            }
          ]
        }
      })

    %{space: space, notebook: notebook}
  end

  describe "versioning UI" do
    test "shows checkpoint button", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      assert html =~ "Checkpoint"
    end

    test "shows versions button", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      assert html =~ "Versions"
    end

    test "toggle-versions shows version panel", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      html = render_click(view, "toggle-versions", %{})
      assert html =~ "Version History"
      assert html =~ "No versions yet"
    end

    test "create-checkpoint creates a version", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      # Toggle versions panel on first
      render_click(view, "toggle-versions", %{})
      html = render_click(view, "create-checkpoint", %{})

      assert html =~ "v1"
      assert html =~ "Checkpoint"
    end
  end

  describe "server execution" do
    test "elixir cells show run button", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      # ELIXIR label should be present
      assert html =~ "ELIXIR"
    end

    test "run-cell for elixir cell shows upgrade message on free plan", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      html = render_click(view, "run-cell", %{"cell-id" => "elixir-1"})
      assert html =~ "Server-side execution requires a Pro plan"
    end

    test "cyanea cells still use client-side execution", %{
      conn: conn,
      user: user,
      space: space
    } do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      html = render_click(view, "run-cell", %{"cell-id" => "code-1"})
      # Should show running spinner for cyanea too
      assert html =~ "Running..."
    end
  end

  describe "coming soon languages" do
    test "python cells show coming soon badge", %{conn: conn, user: user, space: space} do
      # Add a python cell
      notebook = Cyanea.Notebooks.get_notebook_by_slug(space.id, "collab-test")
      {:ok, notebook} = Cyanea.Notebooks.add_cell(notebook, "code")
      cells = Cyanea.Notebooks.get_cells(notebook)
      new_cell = List.last(cells)
      {:ok, _} = Cyanea.Notebooks.update_cell(notebook, new_cell["id"], %{"language" => "python"})

      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      assert html =~ "Coming soon"
    end
  end

  describe "PubSub cell result handling" do
    test "handle_info :cell_result updates outputs", %{
      conn: conn,
      user: user,
      space: space,
      notebook: notebook
    } do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/collab-test")

      # Simulate a PubSub cell_result message
      send(view.pid, {:cell_result, %{
        cell_id: "elixir-1",
        output: %{"type" => "text", "data" => "55", "timing_ms" => 12},
        status: "completed"
      }})

      html = render(view)
      assert html =~ "OUTPUT"
      assert html =~ "12ms"
    end
  end
end

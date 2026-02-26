defmodule CyaneaWeb.NotebookLive.ExecutionTest do
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
        title: "Execution Test",
        slug: "execution-test",
        content: %{
          "cells" => [
            %{
              "id" => "md-cell",
              "type" => "markdown",
              "source" => "# Analysis",
              "position" => 0
            },
            %{
              "id" => "cyanea-cell",
              "type" => "code",
              "source" => "Seq.gcContent(\"ATGC\")",
              "language" => "cyanea",
              "position" => 1
            },
            %{
              "id" => "elixir-cell",
              "type" => "code",
              "source" => "IO.puts(\"hi\")",
              "language" => "elixir",
              "position" => 2
            }
          ]
        }
      })

    %{space: space, notebook: notebook}
  end

  describe "execution assigns" do
    test "mounts with empty cell_outputs and running_cells", %{
      conn: conn,
      user: user,
      space: space
    } do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      # The view should have mounted successfully with execution state
      assert render(view) =~ "Execution Test"
    end
  end

  describe "run-cell event" do
    test "pushes execute-cell for cyanea cells", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      html = render_click(view, "run-cell", %{"cell-id" => "cyanea-cell"})
      # The running spinner should appear
      assert html =~ "Running..."
    end

    test "does not execute non-cyanea cells", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      html = render_click(view, "run-cell", %{"cell-id" => "elixir-cell"})
      refute html =~ "Running..."
    end
  end

  describe "cell-result event" do
    test "stores output in assigns", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      output = %{"type" => "text", "data" => "0.5", "timing_ms" => 42}

      html =
        render_click(view, "cell-result", %{
          "cell-id" => "cyanea-cell",
          "output" => output
        })

      assert html =~ "OUTPUT"
      assert html =~ "42ms"
    end
  end

  describe "clear-outputs event" do
    test "resets cell outputs", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      # First add an output
      render_click(view, "cell-result", %{
        "cell-id" => "cyanea-cell",
        "output" => %{"type" => "text", "data" => "0.5", "timing_ms" => 10}
      })

      # Then clear
      html = render_click(view, "clear-outputs", %{})
      refute html =~ "OUTPUT"
    end
  end

  describe "run-all event" do
    test "marks executable cells as running", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      html = render_click(view, "run-all", %{})
      # Should show running state for cyanea cells
      assert html =~ "Running..."
    end
  end

  describe "UI elements" do
    test "shows Run All button when executable cells exist", %{
      conn: conn,
      user: user,
      space: space
    } do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      assert html =~ "Run All"
    end

    test "shows Server only badge for non-cyanea code cells", %{
      conn: conn,
      user: user,
      space: space
    } do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      assert html =~ "Server only"
    end

    test "shows CYANEA label for cyanea cells", %{conn: conn, user: user, space: space} do
      {:ok, _view, html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      assert html =~ "CYANEA"
    end

    test "new code cells default to cyanea language", %{conn: conn, user: user, space: space} do
      {:ok, view, _html} =
        live(conn, ~p"/#{user.username}/#{space.slug}/notebooks/execution-test")

      html = render_click(view, "add-cell", %{"type" => "code"})
      # Should show CYANEA (the new default)
      # Count occurrences - should have 2 now (original + new)
      assert length(Regex.scan(~r/CYANEA/, html)) >= 2
    end
  end
end

defmodule Cyanea.Workers.CellExecutionWorkerTest do
  use Cyanea.DataCase, async: false
  use Oban.Testing, repo: Cyanea.Repo

  alias Cyanea.Workers.CellExecutionWorker

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.NotebooksFixtures

  setup do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})

    notebook =
      notebook_fixture(%{
        space_id: space.id,
        content: %{
          "cells" => [
            %{
              "id" => "elixir-1",
              "type" => "code",
              "source" => "Enum.map(1..3, & &1 * 2)",
              "language" => "elixir",
              "position" => 0
            }
          ]
        }
      })

    # Subscribe to PubSub for the notebook
    Phoenix.PubSub.subscribe(Cyanea.PubSub, "notebook:#{notebook.id}")

    %{notebook: notebook, user: user}
  end

  describe "perform/1" do
    test "executes elixir code and persists result", %{notebook: notebook, user: user} do
      assert :ok =
               perform_job(CellExecutionWorker, %{
                 notebook_id: notebook.id,
                 cell_id: "elixir-1",
                 source: "Enum.map(1..3, & &1 * 2)",
                 language: "elixir",
                 user_id: user.id
               })

      # Should have received a PubSub broadcast
      assert_received {:cell_result, %{cell_id: "elixir-1", output: output, status: "completed"}}
      assert output["type"] == "text"
      assert output["data"] =~ "[2, 4, 6]"
    end

    test "handles elixir errors", %{notebook: notebook, user: user} do
      assert :ok =
               perform_job(CellExecutionWorker, %{
                 notebook_id: notebook.id,
                 cell_id: "elixir-1",
                 source: "1 / 0",
                 language: "elixir",
                 user_id: user.id
               })

      assert_received {:cell_result, %{cell_id: "elixir-1", status: "error", output: output}}
      assert output["type"] == "error"
      assert output["data"] =~ "ArithmeticError"
    end

    test "blocks dangerous code", %{notebook: notebook, user: user} do
      assert :ok =
               perform_job(CellExecutionWorker, %{
                 notebook_id: notebook.id,
                 cell_id: "elixir-1",
                 source: ~s|System.cmd("ls", [])|,
                 language: "elixir",
                 user_id: user.id
               })

      assert_received {:cell_result, %{cell_id: "elixir-1", status: "error", output: output}}
      assert output["data"] =~ "System"
    end

    test "returns coming soon for unsupported languages", %{notebook: notebook, user: user} do
      assert :ok =
               perform_job(CellExecutionWorker, %{
                 notebook_id: notebook.id,
                 cell_id: "elixir-1",
                 source: "print('hi')",
                 language: "python",
                 user_id: user.id
               })

      assert_received {:cell_result, %{status: "error", output: output}}
      assert output["data"] =~ "coming soon"
    end

    test "persists result to database", %{notebook: notebook, user: user} do
      perform_job(CellExecutionWorker, %{
        notebook_id: notebook.id,
        cell_id: "elixir-1",
        source: "42",
        language: "elixir",
        user_id: user.id
      })

      results = Cyanea.Notebooks.load_execution_results(notebook.id)
      assert Map.has_key?(results, "elixir-1")
      assert results["elixir-1"]["data"] =~ "42"
    end
  end
end

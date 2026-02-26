defmodule Cyanea.NotebooksCellsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Notebooks

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.NotebooksFixtures

  setup do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    notebook = notebook_fixture(%{space_id: space.id, content: %{"cells" => []}})
    %{notebook: notebook, space: space, user: user}
  end

  describe "add_cell/3" do
    test "appends a markdown cell to an empty notebook", %{notebook: notebook} do
      {:ok, updated} = Notebooks.add_cell(notebook, "markdown")
      cells = Notebooks.get_cells(updated)

      assert length(cells) == 1
      assert hd(cells)["type"] == "markdown"
      assert hd(cells)["position"] == 0
      assert hd(cells)["id"] != nil
    end

    test "appends a code cell with default language", %{notebook: notebook} do
      {:ok, updated} = Notebooks.add_cell(notebook, "code")
      cells = Notebooks.get_cells(updated)

      assert length(cells) == 1
      assert hd(cells)["type"] == "code"
      assert hd(cells)["language"] == "cyanea"
    end

    test "inserts cell at specific position", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      {:ok, updated} = Notebooks.add_cell(notebook, "code", 1)

      cells = Notebooks.get_cells(updated)
      assert length(cells) == 3
      assert Enum.at(cells, 1)["type"] == "code"
      assert Enum.map(cells, & &1["position"]) == [0, 1, 2]
    end
  end

  describe "remove_cell/2" do
    test "removes a cell and reindexes", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      {:ok, notebook} = Notebooks.add_cell(notebook, "code")
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")

      cells = Notebooks.get_cells(notebook)
      cell_to_remove = Enum.at(cells, 1)

      {:ok, updated} = Notebooks.remove_cell(notebook, cell_to_remove["id"])
      remaining = Notebooks.get_cells(updated)

      assert length(remaining) == 2
      assert Enum.map(remaining, & &1["position"]) == [0, 1]
      refute Enum.any?(remaining, &(&1["id"] == cell_to_remove["id"]))
    end

    test "removing nonexistent cell is a no-op", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      {:ok, updated} = Notebooks.remove_cell(notebook, "nonexistent-id")
      assert length(Notebooks.get_cells(updated)) == 1
    end
  end

  describe "update_cell/3" do
    test "updates cell source", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      cell_id = hd(Notebooks.get_cells(notebook))["id"]

      {:ok, updated} = Notebooks.update_cell(notebook, cell_id, %{"source" => "# Hello"})
      cell = hd(Notebooks.get_cells(updated))
      assert cell["source"] == "# Hello"
    end

    test "updates code cell language", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "code")
      cell_id = hd(Notebooks.get_cells(notebook))["id"]

      {:ok, updated} = Notebooks.update_cell(notebook, cell_id, %{"language" => "python"})
      cell = hd(Notebooks.get_cells(updated))
      assert cell["language"] == "python"
    end
  end

  describe "move_cell/3" do
    test "moves a cell down", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      {:ok, notebook} = Notebooks.add_cell(notebook, "code")
      first_id = hd(Notebooks.get_cells(notebook))["id"]

      {:ok, updated} = Notebooks.move_cell(notebook, first_id, :down)
      cells = Notebooks.get_cells(updated)
      assert Enum.at(cells, 1)["id"] == first_id
    end

    test "moves a cell up", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      {:ok, notebook} = Notebooks.add_cell(notebook, "code")
      second_id = Enum.at(Notebooks.get_cells(notebook), 1)["id"]

      {:ok, updated} = Notebooks.move_cell(notebook, second_id, :up)
      cells = Notebooks.get_cells(updated)
      assert hd(cells)["id"] == second_id
    end

    test "moving first cell up is a no-op", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      first_id = hd(Notebooks.get_cells(notebook))["id"]

      {:ok, updated} = Notebooks.move_cell(notebook, first_id, :up)
      assert hd(Notebooks.get_cells(updated))["id"] == first_id
    end

    test "moving last cell down is a no-op", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      last_id = hd(Notebooks.get_cells(notebook))["id"]

      {:ok, updated} = Notebooks.move_cell(notebook, last_id, :down)
      assert hd(Notebooks.get_cells(updated))["id"] == last_id
    end
  end

  describe "get_cells/1" do
    test "returns empty list for nil content" do
      notebook = %Cyanea.Notebooks.Notebook{content: nil}
      assert Notebooks.get_cells(notebook) == []
    end

    test "returns empty list for empty content" do
      notebook = %Cyanea.Notebooks.Notebook{content: %{}}
      assert Notebooks.get_cells(notebook) == []
    end

    test "returns cells from content", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.add_cell(notebook, "markdown")
      assert length(Notebooks.get_cells(notebook)) == 1
    end
  end

  describe "executable_cell?/1" do
    test "returns true for cyanea code cells" do
      cell = %{"type" => "code", "language" => "cyanea"}
      assert Notebooks.executable_cell?(cell)
    end

    test "returns true for elixir code cells" do
      cell = %{"type" => "code", "language" => "elixir"}
      assert Notebooks.executable_cell?(cell)
    end

    test "returns false for non-executable code cells" do
      refute Notebooks.executable_cell?(%{"type" => "code", "language" => "python"})
      refute Notebooks.executable_cell?(%{"type" => "code", "language" => "r"})
    end

    test "returns false for markdown cells" do
      refute Notebooks.executable_cell?(%{"type" => "markdown"})
    end

    test "returns false for nil" do
      refute Notebooks.executable_cell?(nil)
    end
  end

  describe "server_executable_cell?/1" do
    test "returns true for elixir code cells" do
      assert Notebooks.server_executable_cell?(%{"type" => "code", "language" => "elixir"})
    end

    test "returns false for cyanea code cells" do
      refute Notebooks.server_executable_cell?(%{"type" => "code", "language" => "cyanea"})
    end

    test "returns false for other languages" do
      refute Notebooks.server_executable_cell?(%{"type" => "code", "language" => "python"})
    end
  end

  describe "change_notebook/2" do
    test "returns a changeset", %{notebook: notebook} do
      changeset = Notebooks.change_notebook(notebook)
      assert %Ecto.Changeset{} = changeset
    end
  end
end

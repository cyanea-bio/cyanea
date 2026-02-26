defmodule Cyanea.Notebooks.VersioningTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Notebooks

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
              "id" => "c1",
              "type" => "markdown",
              "source" => "# Hello",
              "position" => 0
            }
          ]
        }
      })

    %{notebook: notebook, user: user}
  end

  describe "create_version/4" do
    test "creates a version with sequential numbering", %{notebook: notebook, user: user} do
      {:ok, v1} = Notebooks.create_version(notebook, "manual", user.id, "First")
      assert v1.number == 1
      assert v1.label == "First"
      assert v1.trigger == "manual"
      assert v1.content == notebook.content

      # Change content so dedup doesn't kick in
      {:ok, notebook} = Notebooks.update_cell(notebook, "c1", %{"source" => "# Changed"})

      {:ok, v2} = Notebooks.create_version(notebook, "checkpoint", user.id, "Second")
      assert v2.number == 2
    end

    test "deduplicates by content hash", %{notebook: notebook, user: user} do
      {:ok, v1} = Notebooks.create_version(notebook, "manual", user.id)
      {:ok, v2} = Notebooks.create_version(notebook, "manual", user.id)

      # Same content => returns existing version
      assert v1.id == v2.id
    end

    test "creates new version when content changes", %{notebook: notebook, user: user} do
      {:ok, v1} = Notebooks.create_version(notebook, "manual", user.id)

      # Update notebook content
      {:ok, notebook} =
        Notebooks.update_cell(notebook, "c1", %{"source" => "# Updated"})

      {:ok, v2} = Notebooks.create_version(notebook, "manual", user.id)
      assert v2.number == v1.number + 1
      assert v2.content != v1.content
    end

    test "works without author", %{notebook: notebook} do
      {:ok, version} = Notebooks.create_version(notebook, "auto")
      assert version.number == 1
      assert is_nil(version.author_id)
    end
  end

  describe "list_versions/2" do
    test "lists versions in descending order", %{notebook: notebook, user: user} do
      {:ok, _} = Notebooks.create_version(notebook, "manual", user.id, "V1")

      {:ok, notebook} =
        Notebooks.update_cell(notebook, "c1", %{"source" => "# V2"})

      {:ok, _} = Notebooks.create_version(notebook, "checkpoint", user.id, "V2")

      versions = Notebooks.list_versions(notebook.id)
      assert length(versions) == 2
      assert hd(versions).number == 2
    end

    test "respects limit option", %{notebook: notebook, user: user} do
      for i <- 1..5 do
        {:ok, notebook} =
          Notebooks.update_cell(notebook, "c1", %{"source" => "# V#{i}"})

        Notebooks.create_version(notebook, "manual", user.id, "V#{i}")
      end

      assert length(Notebooks.list_versions(notebook.id, limit: 3)) == 3
    end
  end

  describe "get_version!/1" do
    test "returns version with preloaded author", %{notebook: notebook, user: user} do
      {:ok, version} = Notebooks.create_version(notebook, "manual", user.id)
      fetched = Notebooks.get_version!(version.id)

      assert fetched.id == version.id
      assert fetched.author.username == user.username
    end
  end

  describe "get_latest_version/1" do
    test "returns the latest version", %{notebook: notebook, user: user} do
      {:ok, _} = Notebooks.create_version(notebook, "manual", user.id, "V1")

      {:ok, notebook} =
        Notebooks.update_cell(notebook, "c1", %{"source" => "# V2"})

      {:ok, v2} = Notebooks.create_version(notebook, "manual", user.id, "V2")

      latest = Notebooks.get_latest_version(notebook.id)
      assert latest.id == v2.id
    end

    test "returns nil when no versions exist", %{notebook: notebook} do
      assert is_nil(Notebooks.get_latest_version(notebook.id))
    end
  end

  describe "restore_version/3" do
    test "restores notebook to previous version content", %{notebook: notebook, user: user} do
      # Create a version with original content
      {:ok, v1} = Notebooks.create_version(notebook, "manual", user.id, "Original")

      # Modify the notebook
      {:ok, notebook} =
        Notebooks.update_cell(notebook, "c1", %{"source" => "# Modified"})

      # Restore to v1
      {:ok, restored} = Notebooks.restore_version(notebook, v1.id, user.id)

      cells = Notebooks.get_cells(restored)
      assert hd(cells)["source"] == "# Hello"
    end

    test "creates a 'Before restore' snapshot", %{notebook: notebook, user: user} do
      {:ok, v1} = Notebooks.create_version(notebook, "manual", user.id)

      {:ok, notebook} =
        Notebooks.update_cell(notebook, "c1", %{"source" => "# Changed"})

      {:ok, _restored} = Notebooks.restore_version(notebook, v1.id, user.id)

      versions = Notebooks.list_versions(notebook.id)
      labels = Enum.map(versions, & &1.label)
      assert "Before restore" in labels
    end
  end
end

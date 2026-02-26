defmodule Cyanea.NotebooksTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Notebooks

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.NotebooksFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "create_notebook/1" do
    setup :setup_space

    test "creates a notebook", %{space: space} do
      attrs = valid_notebook_attributes(%{space_id: space.id})
      assert {:ok, notebook} = Notebooks.create_notebook(attrs)
      assert notebook.title == attrs.title
      assert notebook.slug == attrs.slug
      assert notebook.space_id == space.id
    end

    test "enforces unique slug per space", %{space: space} do
      attrs = valid_notebook_attributes(%{space_id: space.id, slug: "unique-slug"})
      assert {:ok, _} = Notebooks.create_notebook(attrs)
      assert {:error, changeset} = Notebooks.create_notebook(attrs)
      assert errors_on(changeset)[:slug]
    end
  end

  describe "list_space_notebooks/1" do
    setup :setup_space

    test "lists notebooks for a space", %{space: space} do
      _n1 = notebook_fixture(%{space_id: space.id})
      _n2 = notebook_fixture(%{space_id: space.id})

      notebooks = Notebooks.list_space_notebooks(space.id)
      assert length(notebooks) == 2
    end

    test "does not return notebooks from other spaces", %{user: user, space: space} do
      other_space = space_fixture(%{owner_type: "user", owner_id: user.id})
      _n = notebook_fixture(%{space_id: other_space.id})

      assert Notebooks.list_space_notebooks(space.id) == []
    end
  end

  describe "get_notebook!/1" do
    setup :setup_space

    test "returns the notebook", %{space: space} do
      notebook = notebook_fixture(%{space_id: space.id})
      found = Notebooks.get_notebook!(notebook.id)
      assert found.id == notebook.id
    end

    test "raises for non-existent ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Notebooks.get_notebook!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_notebook_by_slug/2" do
    setup :setup_space

    test "returns notebook for valid space and slug", %{space: space} do
      notebook = notebook_fixture(%{space_id: space.id})
      found = Notebooks.get_notebook_by_slug(space.id, notebook.slug)
      assert found.id == notebook.id
    end

    test "returns nil for non-existent slug", %{space: space} do
      assert Notebooks.get_notebook_by_slug(space.id, "nonexistent") == nil
    end
  end

  describe "update_notebook/2" do
    setup :setup_space

    test "updates fields", %{space: space} do
      notebook = notebook_fixture(%{space_id: space.id})
      assert {:ok, updated} = Notebooks.update_notebook(notebook, %{title: "Updated Title"})
      assert updated.title == "Updated Title"
    end
  end

  describe "delete_notebook/1" do
    setup :setup_space

    test "deletes the notebook", %{space: space} do
      notebook = notebook_fixture(%{space_id: space.id})
      assert {:ok, _} = Notebooks.delete_notebook(notebook)

      assert_raise Ecto.NoResultsError, fn ->
        Notebooks.get_notebook!(notebook.id)
      end
    end
  end

  describe "create_version/4 version cap" do
    setup :setup_space

    test "creates versions within free limit", %{space: space} do
      notebook = notebook_fixture(%{space_id: space.id})
      assert {:ok, version} = Notebooks.create_version(notebook, "manual")
      assert version.number == 1
    end

    test "stops creating versions when free limit reached", %{space: space} do
      notebook = notebook_fixture(%{space_id: space.id})

      # Create 20 versions (free limit)
      for i <- 1..20 do
        # Update notebook content to bypass dedup
        {:ok, updated} =
          Notebooks.update_notebook(notebook, %{
            content: %{"cells" => [%{"id" => "cell-#{i}", "type" => "code", "source" => "v#{i}", "language" => "cyanea", "position" => 0}]}
          })

        assert {:ok, _version} = Notebooks.create_version(updated, "manual")
      end

      # 21st version should be silently skipped (returns latest)
      {:ok, updated} =
        Notebooks.update_notebook(notebook, %{
          content: %{"cells" => [%{"id" => "cell-21", "type" => "code", "source" => "v21", "language" => "cyanea", "position" => 0}]}
        })

      assert {:ok, version} = Notebooks.create_version(updated, "manual")
      # Should return the existing version 20, not create 21
      assert version.number == 20
    end
  end
end

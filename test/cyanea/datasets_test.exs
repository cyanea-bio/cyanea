defmodule Cyanea.DatasetsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Datasets

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.DatasetsFixtures
  import Cyanea.BlobsFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "create_dataset/1" do
    setup :setup_space

    test "creates a dataset", %{space: space} do
      attrs = valid_dataset_attributes(%{space_id: space.id})
      assert {:ok, dataset} = Datasets.create_dataset(attrs)
      assert dataset.name == attrs.name
      assert dataset.slug == attrs.slug
      assert dataset.space_id == space.id
    end

    test "enforces unique slug per space", %{space: space} do
      attrs = valid_dataset_attributes(%{space_id: space.id, slug: "unique-slug"})
      assert {:ok, _} = Datasets.create_dataset(attrs)
      assert {:error, changeset} = Datasets.create_dataset(attrs)
      assert errors_on(changeset)[:slug]
    end

    test "fails without required fields" do
      assert {:error, changeset} = Datasets.create_dataset(%{name: "test"})
      assert errors_on(changeset) != %{}
    end
  end

  describe "list_space_datasets/1" do
    setup :setup_space

    test "lists datasets for a space", %{space: space} do
      _d1 = dataset_fixture(%{space_id: space.id})
      _d2 = dataset_fixture(%{space_id: space.id})

      datasets = Datasets.list_space_datasets(space.id)
      assert length(datasets) == 2
    end

    test "does not return datasets from other spaces", %{user: user, space: space} do
      other_space = space_fixture(%{owner_type: "user", owner_id: user.id})
      _d = dataset_fixture(%{space_id: other_space.id})

      assert Datasets.list_space_datasets(space.id) == []
    end
  end

  describe "get_dataset!/1" do
    setup :setup_space

    test "returns the dataset", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      found = Datasets.get_dataset!(dataset.id)
      assert found.id == dataset.id
    end

    test "raises for non-existent ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Datasets.get_dataset!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_dataset_by_slug/2" do
    setup :setup_space

    test "returns dataset for valid space and slug", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      found = Datasets.get_dataset_by_slug(space.id, dataset.slug)
      assert found.id == dataset.id
    end

    test "returns nil for non-existent slug", %{space: space} do
      assert Datasets.get_dataset_by_slug(space.id, "nonexistent") == nil
    end
  end

  describe "update_dataset/2" do
    setup :setup_space

    test "updates fields", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      assert {:ok, updated} = Datasets.update_dataset(dataset, %{description: "new desc"})
      assert updated.description == "new desc"
    end
  end

  describe "delete_dataset/1" do
    setup :setup_space

    test "deletes the dataset", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      assert {:ok, _} = Datasets.delete_dataset(dataset)

      assert_raise Ecto.NoResultsError, fn ->
        Datasets.get_dataset!(dataset.id)
      end
    end
  end

  describe "attach_file/3" do
    setup :setup_space

    test "attaches blob to dataset", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      blob = blob_fixture()
      assert {:ok, df} = Datasets.attach_file(dataset, blob.id, "data/file.csv")
      assert df.dataset_id == dataset.id
      assert df.blob_id == blob.id
      assert df.path == "data/file.csv"
    end

    test "enforces unique path per dataset", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      blob1 = blob_fixture()
      blob2 = blob_fixture()
      assert {:ok, _} = Datasets.attach_file(dataset, blob1.id, "data/same.csv")
      assert {:error, changeset} = Datasets.attach_file(dataset, blob2.id, "data/same.csv")
      assert errors_on(changeset)[:dataset_id] || errors_on(changeset)[:path]
    end
  end

  describe "list_dataset_files/1" do
    setup :setup_space

    test "lists files for a dataset", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      blob = blob_fixture()
      {:ok, _} = Datasets.attach_file(dataset, blob.id, "data/file.csv")

      files = Datasets.list_dataset_files(dataset.id)
      assert length(files) == 1
      assert hd(files).blob != nil
    end

    test "returns empty list for dataset with no files", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      assert Datasets.list_dataset_files(dataset.id) == []
    end
  end

  describe "detach_file/1" do
    setup :setup_space

    test "removes dataset file", %{space: space} do
      dataset = dataset_fixture(%{space_id: space.id})
      blob = blob_fixture()
      {:ok, df} = Datasets.attach_file(dataset, blob.id, "data/file.csv")

      assert {:ok, _} = Datasets.detach_file(df.id)
      assert Datasets.list_dataset_files(dataset.id) == []
    end
  end
end

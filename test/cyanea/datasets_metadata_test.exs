defmodule Cyanea.DatasetsMetadataTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Datasets

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.DatasetsFixtures

  setup do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    dataset = dataset_fixture(%{space_id: space.id, metadata: %{}, tags: ["genomics"]})
    %{dataset: dataset, space: space, user: user}
  end

  describe "update_metadata/2" do
    test "merges metadata into existing", %{dataset: dataset} do
      {:ok, updated} = Datasets.update_metadata(dataset, %{"row_count" => 1000})
      assert updated.metadata["row_count"] == 1000
    end

    test "preserves existing metadata keys", %{dataset: dataset} do
      {:ok, dataset} = Datasets.update_metadata(dataset, %{"row_count" => 1000})
      {:ok, updated} = Datasets.update_metadata(dataset, %{"column_count" => 5})

      assert updated.metadata["row_count"] == 1000
      assert updated.metadata["column_count"] == 5
    end

    test "overwrites existing keys", %{dataset: dataset} do
      {:ok, dataset} = Datasets.update_metadata(dataset, %{"row_count" => 1000})
      {:ok, updated} = Datasets.update_metadata(dataset, %{"row_count" => 2000})

      assert updated.metadata["row_count"] == 2000
    end
  end

  describe "update_tags/2" do
    test "replaces tags", %{dataset: dataset} do
      assert dataset.tags == ["genomics"]

      {:ok, updated} = Datasets.update_tags(dataset, ["proteomics", "human"])
      assert updated.tags == ["proteomics", "human"]
    end

    test "can set empty tags", %{dataset: dataset} do
      {:ok, updated} = Datasets.update_tags(dataset, [])
      assert updated.tags == []
    end
  end

  describe "compute_stats/1" do
    test "returns zero stats for dataset with no files", %{dataset: dataset} do
      stats = Datasets.compute_stats(dataset.id)

      assert stats.total_size == 0
      assert stats.file_count == 0
      assert stats.formats == []
    end
  end

  describe "change_dataset/2" do
    test "returns a changeset", %{dataset: dataset} do
      changeset = Datasets.change_dataset(dataset)
      assert %Ecto.Changeset{} = changeset
    end
  end
end

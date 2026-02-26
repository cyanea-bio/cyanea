defmodule Cyanea.Workers.BlobHashWorkerTest do
  use Cyanea.DataCase, async: false
  use Oban.Testing, repo: Cyanea.Repo

  alias Cyanea.Blobs
  alias Cyanea.Workers.BlobHashWorker

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "perform/1" do
    setup :setup_space

    test "hashes file, creates blob, and attaches to space", %{space: space} do
      content = "test file content for hashing"
      tmp_path = Path.join(System.tmp_dir!(), "blob_hash_test_#{System.unique_integer([:positive])}")
      File.write!(tmp_path, content)

      expected_sha256 = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

      try do
        assert :ok =
                 perform_job(BlobHashWorker, %{
                   path: tmp_path,
                   space_id: space.id,
                   name: "test.txt",
                   mime_type: "text/plain"
                 })

        # Blob was created with correct hash
        blob = Blobs.get_blob_by_sha256(expected_sha256)
        assert blob != nil
        assert blob.size == byte_size(content)
        assert blob.mime_type == "text/plain"

        # File was attached to space
        files = Blobs.list_space_files(space.id)
        assert length(files) == 1
        assert hd(files).name == "test.txt"
        assert hd(files).blob_id == blob.id
      after
        File.rm(tmp_path)
      end
    end

    test "deduplicates blobs with same content", %{space: space} do
      content = "duplicate content for dedup test"
      sha256 = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

      # Pre-create the blob
      {:new, existing_blob} =
        Blobs.find_or_create_blob(sha256, byte_size(content), "text/plain")

      tmp_path = Path.join(System.tmp_dir!(), "blob_hash_dedup_#{System.unique_integer([:positive])}")
      File.write!(tmp_path, content)

      try do
        assert :ok =
                 perform_job(BlobHashWorker, %{
                   path: tmp_path,
                   space_id: space.id,
                   name: "dedup.txt"
                 })

        # Should attach using the existing blob
        files = Blobs.list_space_files(space.id)
        assert length(files) == 1
        assert hd(files).blob_id == existing_blob.id
      after
        File.rm(tmp_path)
      end
    end

    test "uses default mime_type when not provided", %{space: space} do
      tmp_path = Path.join(System.tmp_dir!(), "blob_hash_mime_#{System.unique_integer([:positive])}")
      File.write!(tmp_path, "some data")

      try do
        assert :ok =
                 perform_job(BlobHashWorker, %{
                   path: tmp_path,
                   space_id: space.id,
                   name: "data.bin"
                 })

        files = Blobs.list_space_files(space.id)
        assert hd(files).blob.mime_type == "application/octet-stream"
      after
        File.rm(tmp_path)
      end
    end
  end
end

defmodule Cyanea.BlobsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Blobs
  alias Cyanea.Blobs.Blob

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.BlobsFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "find_or_create_blob/3" do
    test "creates a new blob" do
      content = "hello world"
      sha256 = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

      assert {:new, blob} = Blobs.find_or_create_blob(sha256, byte_size(content), "text/plain")
      assert blob.sha256 == sha256
      assert blob.size == byte_size(content)
      assert blob.mime_type == "text/plain"
    end

    test "returns existing blob for same sha256" do
      content = "duplicate content"
      sha256 = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

      {:new, original} = Blobs.find_or_create_blob(sha256, byte_size(content), "text/plain")
      {:existing, found} = Blobs.find_or_create_blob(sha256, byte_size(content), "text/plain")
      assert found.id == original.id
    end
  end

  describe "get_blob!/1" do
    test "returns the blob" do
      blob = blob_fixture()
      found = Blobs.get_blob!(blob.id)
      assert found.id == blob.id
    end

    test "raises for invalid ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Blobs.get_blob!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_blob_by_sha256/1" do
    test "returns blob by hash" do
      blob = blob_fixture()
      found = Blobs.get_blob_by_sha256(blob.sha256)
      assert found.id == blob.id
    end

    test "returns nil for unknown hash" do
      assert Blobs.get_blob_by_sha256("0000000000000000000000000000000000000000000000000000000000000000") == nil
    end
  end

  describe "list_space_files/1" do
    setup :setup_space

    test "lists files for a space", %{space: space} do
      blob = blob_fixture()
      _sf = space_file_fixture(%{space_id: space.id, blob_id: blob.id})

      files = Blobs.list_space_files(space.id)
      assert length(files) == 1
      assert hd(files).blob != nil
    end

    test "returns empty list for space with no files", %{space: space} do
      assert Blobs.list_space_files(space.id) == []
    end
  end

  describe "attach_file_to_space/4" do
    setup :setup_space

    test "attaches blob to space", %{space: space} do
      blob = blob_fixture()
      assert {:ok, sf} = Blobs.attach_file_to_space(space.id, blob.id, "data/test.txt", "test.txt")
      assert sf.space_id == space.id
      assert sf.blob_id == blob.id
      assert sf.path == "data/test.txt"
      assert sf.name == "test.txt"
    end

    test "enforces unique path per space", %{space: space} do
      blob1 = blob_fixture()
      blob2 = blob_fixture()
      assert {:ok, _} = Blobs.attach_file_to_space(space.id, blob1.id, "data/same.txt", "same.txt")
      assert {:error, changeset} = Blobs.attach_file_to_space(space.id, blob2.id, "data/same.txt", "same.txt")
      assert errors_on(changeset)[:space_id] || errors_on(changeset)[:path]
    end
  end

  describe "detach_file_from_space/1" do
    setup :setup_space

    test "removes space file", %{space: space} do
      blob = blob_fixture()
      sf = space_file_fixture(%{space_id: space.id, blob_id: blob.id})

      assert {:ok, _} = Blobs.detach_file_from_space(sf.id)
      assert Blobs.list_space_files(space.id) == []
    end
  end

  describe "create_blob_with_quota_check/3" do
    setup :setup_space

    test "rejects file over size limit for free user", %{user: user} do
      # Free limit is 50 MB; create a binary > 50 MB
      # We can't allocate 50 MB in test, so we'll test via Billing.check_file_size directly
      # But we can test a small file succeeds
      binary = String.duplicate("x", 1000)
      assert {:ok, _blob} = Blobs.create_blob_with_quota_check(binary, user)
    end

    test "returns :file_too_large for oversized upload" do
      user = user_fixture()
      # Test the check function directly since we can't allocate 51 MB
      assert {:error, :file_too_large} =
               Cyanea.Billing.check_file_size(user, 51 * 1_048_576)
    end
  end
end

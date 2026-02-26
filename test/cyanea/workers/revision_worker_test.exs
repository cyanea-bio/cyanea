defmodule Cyanea.Workers.RevisionWorkerTest do
  use Cyanea.DataCase, async: true
  use Oban.Testing, repo: Cyanea.Repo

  alias Cyanea.Revisions
  alias Cyanea.Workers.RevisionWorker

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.BlobsFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "perform/1" do
    setup :setup_space

    test "creates a revision for a space", %{user: user, space: space} do
      assert :ok =
               perform_job(RevisionWorker, %{
                 space_id: space.id,
                 author_id: user.id,
                 summary: "Initial revision"
               })

      revisions = Revisions.list_revisions(space.id)
      assert length(revisions) == 1
      assert hd(revisions).summary == "Initial revision"
      assert hd(revisions).number == 1
      assert hd(revisions).content_hash != nil
    end

    test "computes content hash from space files", %{user: user, space: space} do
      blob = blob_fixture()
      space_file_fixture(%{space_id: space.id, blob_id: blob.id, path: "data.txt", name: "data.txt"})

      assert :ok =
               perform_job(RevisionWorker, %{
                 space_id: space.id,
                 author_id: user.id
               })

      revision = Revisions.get_latest_revision(space.id)
      assert revision.content_hash != nil
      assert String.length(revision.content_hash) == 64
    end

    test "uses default summary when not provided", %{user: user, space: space} do
      assert :ok =
               perform_job(RevisionWorker, %{
                 space_id: space.id,
                 author_id: user.id
               })

      revision = Revisions.get_latest_revision(space.id)
      assert revision.summary == "Auto-generated revision"
    end

    test "creates sequential revisions", %{user: user, space: space} do
      perform_job(RevisionWorker, %{space_id: space.id, author_id: user.id, summary: "First"})
      perform_job(RevisionWorker, %{space_id: space.id, author_id: user.id, summary: "Second"})

      revisions = Revisions.list_revisions(space.id)
      assert length(revisions) == 2
      assert Enum.map(revisions, & &1.number) == [2, 1]
    end
  end
end

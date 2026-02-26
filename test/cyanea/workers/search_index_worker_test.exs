defmodule Cyanea.Workers.SearchIndexWorkerTest do
  use Cyanea.DataCase, async: false
  use Oban.Testing, repo: Cyanea.Repo

  alias Cyanea.Workers.SearchIndexWorker

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  describe "perform/1" do
    test "indexes a space without error" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "public"})

      # Search is disabled in test, so index_space gracefully returns :ok
      assert :ok =
               perform_job(SearchIndexWorker, %{
                 type: "space",
                 id: space.id,
                 action: "index"
               })
    end

    test "deletes a space from index without error" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})

      assert :ok =
               perform_job(SearchIndexWorker, %{
                 type: "space",
                 id: space.id,
                 action: "delete"
               })
    end

    test "indexes a user without error" do
      user = user_fixture()

      assert :ok =
               perform_job(SearchIndexWorker, %{
                 type: "user",
                 id: user.id,
                 action: "index"
               })
    end

    test "deletes a user from index without error" do
      user = user_fixture()

      assert :ok =
               perform_job(SearchIndexWorker, %{
                 type: "user",
                 id: user.id,
                 action: "delete"
               })
    end

    test "handles missing user gracefully" do
      assert :ok =
               perform_job(SearchIndexWorker, %{
                 type: "user",
                 id: Ecto.UUID.generate(),
                 action: "index"
               })
    end
  end
end

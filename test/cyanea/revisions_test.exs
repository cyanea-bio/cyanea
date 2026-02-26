defmodule Cyanea.RevisionsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Revisions
  alias Cyanea.Spaces

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.RevisionsFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "create_revision/1" do
    setup :setup_space

    test "auto-increments number", %{user: user, space: space} do
      attrs = valid_revision_attributes(%{space_id: space.id, author_id: user.id})
      assert {:ok, rev} = Revisions.create_revision(attrs)
      assert rev.number == 1
    end

    test "updates space.current_revision_id", %{user: user, space: space} do
      attrs = valid_revision_attributes(%{space_id: space.id, author_id: user.id})
      {:ok, rev} = Revisions.create_revision(attrs)

      updated_space = Spaces.get_space!(space.id)
      assert updated_space.current_revision_id == rev.id
    end

    test "multiple revisions get sequential numbers", %{user: user, space: space} do
      {:ok, r1} = Revisions.create_revision(valid_revision_attributes(%{space_id: space.id, author_id: user.id}))
      {:ok, r2} = Revisions.create_revision(valid_revision_attributes(%{space_id: space.id, author_id: user.id}))
      {:ok, r3} = Revisions.create_revision(valid_revision_attributes(%{space_id: space.id, author_id: user.id}))

      assert r1.number == 1
      assert r2.number == 2
      assert r3.number == 3
    end
  end

  describe "list_revisions/2" do
    setup :setup_space

    test "returns revisions for space in desc order", %{user: user, space: space} do
      _r1 = revision_fixture(%{space_id: space.id, author_id: user.id})
      _r2 = revision_fixture(%{space_id: space.id, author_id: user.id})
      _r3 = revision_fixture(%{space_id: space.id, author_id: user.id})

      revisions = Revisions.list_revisions(space.id)
      assert length(revisions) == 3
      numbers = Enum.map(revisions, & &1.number)
      assert numbers == [3, 2, 1]
    end
  end

  describe "get_revision!/1" do
    setup :setup_space

    test "returns revision with preloads", %{user: user, space: space} do
      rev = revision_fixture(%{space_id: space.id, author_id: user.id})
      found = Revisions.get_revision!(rev.id)
      assert found.id == rev.id
      assert found.author != nil
      assert found.space != nil
    end

    test "raises for non-existent ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Revisions.get_revision!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_latest_revision/1" do
    setup :setup_space

    test "returns most recent revision", %{user: user, space: space} do
      _r1 = revision_fixture(%{space_id: space.id, author_id: user.id})
      _r2 = revision_fixture(%{space_id: space.id, author_id: user.id})
      r3 = revision_fixture(%{space_id: space.id, author_id: user.id})

      latest = Revisions.get_latest_revision(space.id)
      assert latest.id == r3.id
      assert latest.number == 3
    end

    test "returns nil for space with no revisions", %{space: space} do
      assert Revisions.get_latest_revision(space.id) == nil
    end
  end
end

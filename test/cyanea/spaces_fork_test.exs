defmodule Cyanea.SpacesForkTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Notebooks
  alias Cyanea.Protocols
  alias Cyanea.Spaces

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  defp setup_space(_context) do
    owner = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: owner.id})
    %{owner: owner, space: space}
  end

  describe "fork_space/3" do
    setup :setup_space

    test "creates a forked space with forked_from_id", %{space: space} do
      forker = user_fixture()
      assert {:ok, forked} = Spaces.fork_space(space, forker)

      assert forked.forked_from_id == space.id
      assert forked.owner_type == "user"
      assert forked.owner_id == forker.id
      assert forked.description == space.description
    end

    test "increments fork_count on original space", %{space: space} do
      forker = user_fixture()
      {:ok, _forked} = Spaces.fork_space(space, forker)

      updated = Spaces.get_space!(space.id)
      assert updated.fork_count == 1
    end

    test "copies notebooks", %{space: space} do
      Notebooks.create_notebook(%{
        space_id: space.id,
        title: "Test Notebook",
        slug: "test-notebook",
        content: %{"cells" => [%{"id" => "1", "type" => "markdown", "source" => "hello"}]}
      })

      forker = user_fixture()
      {:ok, forked} = Spaces.fork_space(space, forker)

      forked_notebooks = Notebooks.list_space_notebooks(forked.id)
      assert length(forked_notebooks) == 1
      assert hd(forked_notebooks).title == "Test Notebook"
    end

    test "copies protocols with version reset", %{space: space} do
      Protocols.create_protocol(%{
        space_id: space.id,
        title: "Test Protocol",
        slug: "test-protocol",
        version: "2.3.1",
        content: %{"steps" => []}
      })

      forker = user_fixture()
      {:ok, forked} = Spaces.fork_space(space, forker)

      forked_protocols = Protocols.list_space_protocols(forked.id)
      assert length(forked_protocols) == 1
      assert hd(forked_protocols).version == "1.0.0"
    end
  end

  describe "list_forks/1" do
    setup :setup_space

    test "lists spaces forked from a given space", %{space: space} do
      forker1 = user_fixture()
      forker2 = user_fixture()

      {:ok, _} = Spaces.fork_space(space, forker1)
      {:ok, _} = Spaces.fork_space(space, forker2, %{slug: space.slug <> "-fork2"})

      forks = Spaces.list_forks(space.id)
      assert length(forks) == 2
    end

    test "returns empty list when no forks exist", %{space: space} do
      assert Spaces.list_forks(space.id) == []
    end
  end
end

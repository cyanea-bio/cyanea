defmodule Cyanea.ActivityTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Activity

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "log/4" do
    setup :setup_space

    test "creates an activity event", %{user: user, space: space} do
      assert {:ok, event} =
               Activity.log(user, "created_space", space,
                 space_id: space.id,
                 metadata: %{"name" => space.name}
               )

      assert event.action == "created_space"
      assert event.subject_type == "space"
      assert event.subject_id == space.id
      assert event.actor_id == user.id
      assert event.space_id == space.id
      assert event.metadata["name"] == space.name
    end
  end

  describe "list_global_feed/1" do
    setup :setup_space

    test "returns public events", %{user: user, space: space} do
      Activity.log(user, "created_space", space, space_id: space.id)
      events = Activity.list_global_feed()
      assert length(events) == 1
    end

    test "excludes events from private spaces", %{user: user} do
      private_space =
        space_fixture(%{owner_type: "user", owner_id: user.id, visibility: "private"})

      Activity.log(user, "created_space", private_space, space_id: private_space.id)
      events = Activity.list_global_feed()
      assert events == []
    end
  end

  describe "list_space_feed/2" do
    setup :setup_space

    test "returns events for a specific space", %{user: user, space: space} do
      Activity.log(user, "created_space", space, space_id: space.id)
      Activity.log(user, "created_notebook", {"notebook", Ecto.UUID.generate()},
        space_id: space.id
      )

      events = Activity.list_space_feed(space.id)
      assert length(events) == 2
    end
  end

  describe "list_user_feed/2" do
    setup :setup_space

    test "returns events by a user", %{user: user, space: space} do
      Activity.log(user, "created_space", space, space_id: space.id)
      events = Activity.list_user_feed(user.id)
      assert length(events) == 1
      assert hd(events).actor_id == user.id
    end
  end

  describe "list_following_feed/2" do
    test "falls back to global feed when user follows nobody" do
      user = user_fixture()
      other = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: other.id})
      Activity.log(other, "created_space", space, space_id: space.id)

      events = Activity.list_following_feed(user.id)
      # Falls back to global feed
      assert length(events) == 1
    end

    test "returns events from followed users" do
      user = user_fixture()
      followed = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: followed.id})

      Cyanea.Follows.follow(user.id, "user", followed.id)
      Activity.log(followed, "created_space", space, space_id: space.id)

      events = Activity.list_following_feed(user.id)
      assert length(events) == 1
      assert hd(events).actor_id == followed.id
    end
  end
end

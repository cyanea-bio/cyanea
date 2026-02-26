defmodule Cyanea.NotificationsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Notifications

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  describe "create/6" do
    test "creates a notification" do
      user = user_fixture()
      actor = user_fixture()

      assert {:ok, notification} =
               Notifications.create(
                 user.id,
                 actor.id,
                 "starred",
                 "space",
                 Ecto.UUID.generate()
               )

      assert notification.user_id == user.id
      assert notification.actor_id == actor.id
      assert notification.action == "starred"
    end

    test "skips notification when actor is the user" do
      user = user_fixture()
      assert {:ok, :skipped} = Notifications.create(user.id, user.id, "starred", "space", Ecto.UUID.generate())
    end
  end

  describe "list_unread/2 and list_all/2" do
    test "lists unread notifications" do
      user = user_fixture()
      actor = user_fixture()

      Notifications.create(user.id, actor.id, "starred", "space", Ecto.UUID.generate())
      Notifications.create(user.id, actor.id, "forked", "space", Ecto.UUID.generate())

      unread = Notifications.list_unread(user.id)
      assert length(unread) == 2

      all = Notifications.list_all(user.id)
      assert length(all) == 2
    end
  end

  describe "mark_read/1" do
    test "marks a notification as read" do
      user = user_fixture()
      actor = user_fixture()

      {:ok, notification} =
        Notifications.create(user.id, actor.id, "starred", "space", Ecto.UUID.generate())

      Notifications.mark_read(notification.id)

      unread = Notifications.list_unread(user.id)
      assert unread == []
    end
  end

  describe "mark_all_read/1" do
    test "marks all notifications as read" do
      user = user_fixture()
      actor = user_fixture()

      Notifications.create(user.id, actor.id, "starred", "space", Ecto.UUID.generate())
      Notifications.create(user.id, actor.id, "forked", "space", Ecto.UUID.generate())

      Notifications.mark_all_read(user.id)

      unread = Notifications.list_unread(user.id)
      assert unread == []
    end
  end

  describe "unread_count/1" do
    test "returns the count of unread notifications" do
      user = user_fixture()
      actor = user_fixture()

      assert Notifications.unread_count(user.id) == 0

      Notifications.create(user.id, actor.id, "starred", "space", Ecto.UUID.generate())
      Notifications.create(user.id, actor.id, "forked", "space", Ecto.UUID.generate())

      assert Notifications.unread_count(user.id) == 2
    end
  end

  describe "notify_space_owner/5" do
    test "creates notification for space owner" do
      owner = user_fixture()
      actor = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: owner.id})

      Notifications.notify_space_owner(actor, "starred", space, "space", space.id)

      unread = Notifications.list_unread(owner.id)
      assert length(unread) == 1
      assert hd(unread).action == "starred"
    end

    test "skips notification when actor is the owner" do
      owner = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: owner.id})

      Notifications.notify_space_owner(owner, "starred", space, "space", space.id)

      unread = Notifications.list_unread(owner.id)
      assert unread == []
    end
  end

  describe "notify_discussion_participants/5" do
    test "notifies discussion author and commenters" do
      owner = user_fixture()
      commenter = user_fixture()
      actor = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: owner.id})

      {:ok, discussion} =
        Cyanea.Discussions.create_discussion(space, owner, %{
          title: "Test",
          body: "body"
        })

      # Add a comment from commenter
      Cyanea.Discussions.add_comment(discussion, commenter, %{body: "Comment"})

      Notifications.notify_discussion_participants(
        actor,
        "new_comment",
        discussion,
        "discussion",
        discussion.id
      )

      owner_notifs = Notifications.list_unread(owner.id)
      commenter_notifs = Notifications.list_unread(commenter.id)
      actor_notifs = Notifications.list_unread(actor.id)

      assert length(owner_notifs) == 1
      assert length(commenter_notifs) == 1
      # Actor should not receive notification
      assert actor_notifs == []
    end
  end
end

defmodule Cyanea.DiscussionsTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Discussions
  alias Cyanea.Spaces

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "create_discussion/3" do
    setup :setup_space

    test "creates a discussion and increments space discussion_count", %{user: user, space: space} do
      assert {:ok, discussion} =
               Discussions.create_discussion(space, user, %{
                 title: "Test Discussion",
                 body: "This is a test."
               })

      assert discussion.title == "Test Discussion"
      assert discussion.body == "This is a test."
      assert discussion.status == "open"
      assert discussion.space_id == space.id
      assert discussion.author_id == user.id

      updated_space = Spaces.get_space!(space.id)
      assert updated_space.discussion_count == 1
    end

    test "returns error with invalid data", %{user: user, space: space} do
      assert {:error, changeset} =
               Discussions.create_discussion(space, user, %{title: "", body: ""})

      assert errors_on(changeset) != %{}
    end
  end

  describe "list_space_discussions/2" do
    setup :setup_space

    test "returns discussions for the space", %{user: user, space: space} do
      {:ok, _d1} =
        Discussions.create_discussion(space, user, %{title: "First", body: "body"})

      {:ok, _d2} =
        Discussions.create_discussion(space, user, %{title: "Second", body: "body"})

      discussions = Discussions.list_space_discussions(space.id)
      assert length(discussions) == 2
      titles = Enum.map(discussions, & &1.title)
      assert "First" in titles
      assert "Second" in titles
    end

    test "filters by status", %{user: user, space: space} do
      {:ok, _d1} =
        Discussions.create_discussion(space, user, %{title: "Open", body: "body"})

      {:ok, d2} =
        Discussions.create_discussion(space, user, %{title: "Closed", body: "body"})

      Discussions.close_discussion(d2)

      open = Discussions.list_space_discussions(space.id, status: "open")
      assert length(open) == 1
      assert hd(open).title == "Open"

      closed = Discussions.list_space_discussions(space.id, status: "closed")
      assert length(closed) == 1
      assert hd(closed).title == "Closed"
    end
  end

  describe "close_discussion/1 and reopen_discussion/1" do
    setup :setup_space

    test "closes and reopens a discussion", %{user: user, space: space} do
      {:ok, discussion} =
        Discussions.create_discussion(space, user, %{title: "Test", body: "body"})

      assert discussion.status == "open"

      {:ok, closed} = Discussions.close_discussion(discussion)
      assert closed.status == "closed"

      {:ok, reopened} = Discussions.reopen_discussion(closed)
      assert reopened.status == "open"
    end
  end

  describe "add_comment/3" do
    setup :setup_space

    test "adds a comment and increments comment_count", %{user: user, space: space} do
      {:ok, discussion} =
        Discussions.create_discussion(space, user, %{title: "Test", body: "body"})

      assert {:ok, comment} =
               Discussions.add_comment(discussion, user, %{body: "A comment."})

      assert comment.body == "A comment."
      assert comment.discussion_id == discussion.id
      assert comment.author_id == user.id

      updated = Discussions.get_discussion!(discussion.id)
      assert updated.comment_count == 1
    end

    test "supports replies via parent_comment_id", %{user: user, space: space} do
      {:ok, discussion} =
        Discussions.create_discussion(space, user, %{title: "Test", body: "body"})

      {:ok, parent} =
        Discussions.add_comment(discussion, user, %{body: "Parent comment."})

      {:ok, reply} =
        Discussions.add_comment(discussion, user, %{
          body: "Reply to parent.",
          parent_comment_id: parent.id
        })

      assert reply.parent_comment_id == parent.id
    end
  end

  describe "get_discussion_with_comments/1" do
    setup :setup_space

    test "returns threaded comments", %{user: user, space: space} do
      {:ok, discussion} =
        Discussions.create_discussion(space, user, %{title: "Test", body: "body"})

      {:ok, c1} = Discussions.add_comment(discussion, user, %{body: "Comment 1"})
      {:ok, _c2} = Discussions.add_comment(discussion, user, %{body: "Comment 2"})

      {:ok, _reply} =
        Discussions.add_comment(discussion, user, %{
          body: "Reply to comment 1",
          parent_comment_id: c1.id
        })

      {fetched_discussion, comments} = Discussions.get_discussion_with_comments(discussion.id)

      assert fetched_discussion.id == discussion.id
      # 2 top-level comments
      assert length(comments) == 2
      # First comment has 1 reply
      first = hd(comments)
      assert length(first.replies) == 1
    end
  end

  describe "delete_comment/1" do
    setup :setup_space

    test "deletes comment and decrements counter", %{user: user, space: space} do
      {:ok, discussion} =
        Discussions.create_discussion(space, user, %{title: "Test", body: "body"})

      {:ok, comment} =
        Discussions.add_comment(discussion, user, %{body: "To be deleted"})

      assert {:ok, _} = Discussions.delete_comment(comment)

      updated = Discussions.get_discussion!(discussion.id)
      assert updated.comment_count == 0
    end
  end
end

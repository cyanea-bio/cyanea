defmodule Cyanea.FollowsTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Follows

  import Cyanea.AccountsFixtures

  describe "follow/3" do
    test "creates a follow relationship" do
      follower = user_fixture()
      followed = user_fixture()

      assert {:ok, follow} = Follows.follow(follower.id, "user", followed.id)
      assert follow.follower_id == follower.id
      assert follow.followed_type == "user"
      assert follow.followed_id == followed.id
    end

    test "cannot follow the same target twice" do
      follower = user_fixture()
      followed = user_fixture()

      assert {:ok, _} = Follows.follow(follower.id, "user", followed.id)
      assert {:error, _} = Follows.follow(follower.id, "user", followed.id)
    end
  end

  describe "unfollow/3" do
    test "removes a follow relationship" do
      follower = user_fixture()
      followed = user_fixture()

      {:ok, _} = Follows.follow(follower.id, "user", followed.id)
      assert {:ok, _} = Follows.unfollow(follower.id, "user", followed.id)
      refute Follows.following?(follower.id, "user", followed.id)
    end

    test "returns error when not following" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:error, :not_following} = Follows.unfollow(user1.id, "user", user2.id)
    end
  end

  describe "following?/3" do
    test "returns true when following" do
      follower = user_fixture()
      followed = user_fixture()

      {:ok, _} = Follows.follow(follower.id, "user", followed.id)
      assert Follows.following?(follower.id, "user", followed.id) == true
    end

    test "returns false when not following" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert Follows.following?(user1.id, "user", user2.id) == false
    end
  end

  describe "list_followers/3" do
    test "lists followers of a user" do
      target = user_fixture()
      f1 = user_fixture()
      f2 = user_fixture()

      Follows.follow(f1.id, "user", target.id)
      Follows.follow(f2.id, "user", target.id)

      followers = Follows.list_followers("user", target.id)
      assert length(followers) == 2
    end
  end

  describe "list_following/2" do
    test "lists who a user follows" do
      user = user_fixture()
      t1 = user_fixture()
      t2 = user_fixture()

      Follows.follow(user.id, "user", t1.id)
      Follows.follow(user.id, "user", t2.id)

      following = Follows.list_following(user.id)
      assert length(following) == 2
    end
  end

  describe "follower_count/2 and following_count/1" do
    test "returns correct counts" do
      user = user_fixture()
      t1 = user_fixture()
      t2 = user_fixture()

      Follows.follow(user.id, "user", t1.id)
      Follows.follow(user.id, "user", t2.id)

      assert Follows.follower_count("user", t1.id) == 1
      assert Follows.following_count(user.id) == 2
    end
  end
end

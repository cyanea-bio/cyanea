defmodule Cyanea.DiscussionsFixtures do
  @moduledoc """
  Test helpers for creating discussion entities.
  """

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures

  def valid_discussion_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: "Discussion #{System.unique_integer([:positive])}",
      body: "This is a test discussion body."
    })
  end

  def discussion_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :author, fn -> user_fixture() end)

    space =
      Map.get_lazy(attrs, :space, fn ->
        space_fixture(%{owner_type: "user", owner_id: user.id})
      end)

    disc_attrs = valid_discussion_attributes(Map.drop(attrs, [:author, :space]))
    {:ok, discussion} = Cyanea.Discussions.create_discussion(space, user, disc_attrs)
    discussion
  end

  def comment_fixture(discussion, author, attrs \\ %{}) do
    comment_attrs = Enum.into(attrs, %{body: "A test comment."})
    {:ok, comment} = Cyanea.Discussions.add_comment(discussion, author, comment_attrs)
    comment
  end
end

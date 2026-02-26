defmodule Cyanea.Discussions do
  @moduledoc """
  The Discussions context — threaded discussions within spaces.
  """
  import Ecto.Query

  alias Cyanea.Discussions.{Comment, Discussion}
  alias Cyanea.Repo
  alias Cyanea.Spaces.Space

  ## Listing

  @doc """
  Lists discussions for a space, paginated and ordered by newest first.
  """
  def list_space_discussions(space_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    status = Keyword.get(opts, :status)

    query =
      from(d in Discussion,
        where: d.space_id == ^space_id,
        order_by: [desc: d.inserted_at],
        limit: ^limit,
        preload: [:author]
      )

    query =
      if status do
        from(d in query, where: d.status == ^status)
      else
        query
      end

    Repo.all(query)
  end

  ## Fetching

  @doc """
  Gets a single discussion by ID with preloaded author.
  Raises if not found.
  """
  def get_discussion!(id) do
    Discussion
    |> Repo.get!(id)
    |> Repo.preload(:author)
  end

  @doc """
  Gets a discussion with threaded comments.

  Returns comments sorted by inserted_at, with top-level comments
  and nested replies (one level).
  """
  def get_discussion_with_comments(id) do
    discussion =
      Discussion
      |> Repo.get!(id)
      |> Repo.preload(:author)

    comments =
      from(c in Comment,
        where: c.discussion_id == ^id,
        order_by: [asc: c.inserted_at],
        preload: [:author]
      )
      |> Repo.all()

    # Group into top-level and replies
    {top_level, replies} = Enum.split_with(comments, &is_nil(&1.parent_comment_id))

    replies_by_parent =
      Enum.group_by(replies, & &1.parent_comment_id)

    threaded =
      Enum.map(top_level, fn comment ->
        %{comment | replies: Map.get(replies_by_parent, comment.id, [])}
      end)

    {discussion, threaded}
  end

  ## Create / Update / Delete

  @doc """
  Creates a discussion in a space. Atomically increments space.discussion_count.
  """
  def create_discussion(%Space{} = space, author, attrs) do
    changeset =
      %Discussion{}
      |> Discussion.changeset(Map.merge(attrs, %{space_id: space.id, author_id: author.id}))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:discussion, changeset)
    |> Ecto.Multi.update_all(:increment, fn _changes ->
      from(s in Space, where: s.id == ^space.id, update: [inc: [discussion_count: 1]])
    end, [])
    |> Repo.transaction()
    |> case do
      {:ok, %{discussion: discussion}} ->
        discussion = Repo.preload(discussion, :author)
        {:ok, discussion}

      {:error, :discussion, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Closes a discussion.
  """
  def close_discussion(%Discussion{} = discussion) do
    discussion
    |> Discussion.changeset(%{status: "closed"})
    |> Repo.update()
  end

  @doc """
  Reopens a closed discussion.
  """
  def reopen_discussion(%Discussion{} = discussion) do
    discussion
    |> Discussion.changeset(%{status: "open"})
    |> Repo.update()
  end

  @doc """
  Adds a comment to a discussion. Atomically increments discussion.comment_count.
  """
  def add_comment(%Discussion{} = discussion, author, attrs) do
    changeset =
      %Comment{}
      |> Comment.changeset(
        Map.merge(attrs, %{discussion_id: discussion.id, author_id: author.id})
      )

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:comment, changeset)
    |> Ecto.Multi.update_all(:increment, fn _changes ->
      from(d in Discussion,
        where: d.id == ^discussion.id,
        update: [inc: [comment_count: 1]]
      )
    end, [])
    |> Repo.transaction()
    |> case do
      {:ok, %{comment: comment}} ->
        comment = Repo.preload(comment, :author)
        {:ok, comment}

      {:error, :comment, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a comment. Decrements discussion.comment_count.
  """
  def delete_comment(%Comment{} = comment) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:comment, comment)
    |> Ecto.Multi.update_all(:decrement, fn _changes ->
      from(d in Discussion,
        where: d.id == ^comment.discussion_id and d.comment_count > 0,
        update: [inc: [comment_count: -1]]
      )
    end, [])
    |> Repo.transaction()
    |> case do
      {:ok, %{comment: comment}} -> {:ok, comment}
      {:error, :comment, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Returns a changeset for tracking discussion changes in forms.
  """
  def change_discussion(%Discussion{} = discussion, attrs \\ %{}) do
    Discussion.changeset(discussion, attrs)
  end
end

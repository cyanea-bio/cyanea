defmodule Cyanea.Follows do
  @moduledoc """
  The Follows context — user follows user or organization.
  """
  import Ecto.Query

  alias Cyanea.Follows.Follow
  alias Cyanea.Repo

  @doc """
  Creates a follow relationship.
  """
  def follow(follower_id, followed_type, followed_id) do
    %Follow{}
    |> Follow.changeset(%{
      follower_id: follower_id,
      followed_type: followed_type,
      followed_id: followed_id
    })
    |> Repo.insert()
  end

  @doc """
  Removes a follow relationship.
  """
  def unfollow(follower_id, followed_type, followed_id) do
    case Repo.get_by(Follow,
           follower_id: follower_id,
           followed_type: followed_type,
           followed_id: followed_id
         ) do
      nil -> {:error, :not_following}
      follow -> Repo.delete(follow)
    end
  end

  @doc """
  Returns true if the user follows the target.
  """
  def following?(follower_id, followed_type, followed_id) do
    from(f in Follow,
      where:
        f.follower_id == ^follower_id and
          f.followed_type == ^followed_type and
          f.followed_id == ^followed_id
    )
    |> Repo.exists?()
  end

  @doc """
  Lists followers of a target.
  """
  def list_followers(followed_type, followed_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(f in Follow,
      where: f.followed_type == ^followed_type and f.followed_id == ^followed_id,
      order_by: [desc: f.inserted_at],
      limit: ^limit,
      preload: [:follower]
    )
    |> Repo.all()
  end

  @doc """
  Lists who a user follows.
  """
  def list_following(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(f in Follow,
      where: f.follower_id == ^user_id,
      order_by: [desc: f.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns the follower count for a target.
  """
  def follower_count(followed_type, followed_id) do
    from(f in Follow,
      where: f.followed_type == ^followed_type and f.followed_id == ^followed_id
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the number of targets a user follows.
  """
  def following_count(user_id) do
    from(f in Follow, where: f.follower_id == ^user_id)
    |> Repo.aggregate(:count)
  end
end

defmodule Cyanea.Activity do
  @moduledoc """
  The Activity context — append-only activity event log and feed queries.
  """
  import Ecto.Query

  alias Cyanea.Activity.Event
  alias Cyanea.Follows.Follow
  alias Cyanea.Repo
  alias Cyanea.Spaces.Space

  @doc """
  Logs an activity event.

  ## Examples

      Activity.log(user, "created_space", space, space_id: space.id)
      Activity.log(user, "starred_space", space, space_id: space.id, metadata: %{})
  """
  def log(actor, action, subject, opts \\ []) do
    {subject_type, subject_id} = resolve_subject(subject)

    attrs = %{
      actor_id: actor.id,
      action: action,
      subject_type: subject_type,
      subject_id: subject_id,
      space_id: Keyword.get(opts, :space_id),
      metadata: Keyword.get(opts, :metadata, %{})
    }

    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists the global activity feed — recent public events, paginated.
  """
  def list_global_feed(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(e in Event,
      left_join: s in Space,
      on: e.space_id == s.id,
      where: is_nil(e.space_id) or s.visibility == "public",
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  @doc """
  Lists activity events for a specific space.
  """
  def list_space_feed(space_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(e in Event,
      where: e.space_id == ^space_id,
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  @doc """
  Lists activity events by a specific user.
  """
  def list_user_feed(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(e in Event,
      left_join: s in Space,
      on: e.space_id == s.id,
      where: e.actor_id == ^user_id,
      where: is_nil(e.space_id) or s.visibility == "public",
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  @doc """
  Lists activity events from users the current user follows.
  Falls back to global feed if user follows nobody.
  """
  def list_following_feed(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    followed_user_ids =
      from(f in Follow,
        where: f.follower_id == ^user_id and f.followed_type == "user",
        select: f.followed_id
      )
      |> Repo.all()

    if followed_user_ids == [] do
      list_global_feed(opts)
    else
      from(e in Event,
        left_join: s in Space,
        on: e.space_id == s.id,
        where: e.actor_id in ^followed_user_ids,
        where: is_nil(e.space_id) or s.visibility == "public",
        order_by: [desc: e.inserted_at],
        limit: ^limit,
        preload: [:actor]
      )
      |> Repo.all()
    end
  end

  ## Helpers

  defp resolve_subject(%Cyanea.Spaces.Space{id: id}), do: {"space", id}
  defp resolve_subject(%Cyanea.Notebooks.Notebook{id: id}), do: {"notebook", id}
  defp resolve_subject(%Cyanea.Protocols.Protocol{id: id}), do: {"protocol", id}
  defp resolve_subject(%Cyanea.Datasets.Dataset{id: id}), do: {"dataset", id}
  defp resolve_subject(%Cyanea.Discussions.Discussion{id: id}), do: {"discussion", id}
  defp resolve_subject(%Cyanea.Discussions.Comment{id: id}), do: {"comment", id}
  defp resolve_subject({type, id}) when is_binary(type) and is_binary(id), do: {type, id}
end

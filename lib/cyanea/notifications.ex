defmodule Cyanea.Notifications do
  @moduledoc """
  The Notifications context — user notification management.
  """
  import Ecto.Query

  alias Cyanea.Notifications.Notification
  alias Cyanea.Repo

  @doc """
  Creates a notification.
  """
  def create(user_id, actor_id, action, subject_type, subject_id, opts \\ []) do
    # Don't notify yourself
    if user_id == actor_id do
      {:ok, :skipped}
    else
      %Notification{}
      |> Notification.changeset(%{
        user_id: user_id,
        actor_id: actor_id,
        action: action,
        subject_type: subject_type,
        subject_id: subject_id,
        space_id: Keyword.get(opts, :space_id)
      })
      |> Repo.insert()
    end
  end

  @doc """
  Lists unread notifications for a user.
  """
  def list_unread(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at),
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  @doc """
  Lists all notifications for a user.
  """
  def list_all(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  @doc """
  Marks a single notification as read.
  """
  def mark_read(notification_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(n in Notification, where: n.id == ^notification_id)
    |> Repo.update_all(set: [read_at: now])
  end

  @doc """
  Marks all unread notifications for a user as read.
  """
  def mark_all_read(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: now])
  end

  @doc """
  Returns the count of unread notifications for a user.
  """
  def unread_count(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Notifies the space owner about an action, unless the actor is the owner.
  """
  def notify_space_owner(actor, action, space, subject_type, subject_id) do
    owner_id = resolve_space_owner_id(space)

    if owner_id do
      create(owner_id, actor.id, action, subject_type, subject_id, space_id: space.id)
    else
      {:ok, :skipped}
    end
  end

  @doc """
  Notifies all participants of a discussion (author + commenters), deduplicated, excluding the actor.
  """
  def notify_discussion_participants(actor, action, discussion, subject_type, subject_id) do
    # Gather participant IDs: discussion author + all commenters
    commenter_ids =
      from(c in Cyanea.Discussions.Comment,
        where: c.discussion_id == ^discussion.id and not is_nil(c.author_id),
        select: c.author_id,
        distinct: true
      )
      |> Repo.all()

    participant_ids =
      ([discussion.author_id | commenter_ids])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.reject(&(&1 == actor.id))

    Enum.each(participant_ids, fn user_id ->
      create(user_id, actor.id, action, subject_type, subject_id,
        space_id: discussion.space_id
      )
    end)

    :ok
  end

  ## Helpers

  defp resolve_space_owner_id(%{owner_type: "user", owner_id: owner_id}), do: owner_id
  defp resolve_space_owner_id(_), do: nil
end

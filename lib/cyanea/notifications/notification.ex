defmodule Cyanea.Notifications.Notification do
  @moduledoc """
  Notification schema — user notifications for activity on their content.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @actions ~w(starred forked new_discussion new_comment mentioned)

  schema "notifications" do
    field :action, :string
    field :subject_type, :string
    field :subject_id, :binary_id
    field :read_at, :utc_datetime

    belongs_to :user, Cyanea.Accounts.User
    belongs_to :actor, Cyanea.Accounts.User
    belongs_to :space, Cyanea.Spaces.Space

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :actor_id, :action, :subject_type, :subject_id, :space_id, :read_at])
    |> validate_required([:user_id, :action, :subject_type, :subject_id])
    |> validate_inclusion(:action, @actions)
  end

  def actions, do: @actions
end

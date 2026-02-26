defmodule Cyanea.Follows.Follow do
  @moduledoc """
  Follow schema — a user follows another user or an organization.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @followed_types ~w(user organization)

  schema "follows" do
    field :followed_type, :string
    field :followed_id, :binary_id

    belongs_to :follower, Cyanea.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followed_type, :followed_id])
    |> validate_required([:follower_id, :followed_type, :followed_id])
    |> validate_inclusion(:followed_type, @followed_types)
    |> unique_constraint([:follower_id, :followed_type, :followed_id])
  end

  def followed_types, do: @followed_types
end

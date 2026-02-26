defmodule Cyanea.Discussions.Discussion do
  @moduledoc """
  Discussion schema — threaded discussions within spaces.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(open closed)

  schema "discussions" do
    field :title, :string
    field :body, :string
    field :status, :string, default: "open"
    field :comment_count, :integer, default: 0

    belongs_to :space, Cyanea.Spaces.Space
    belongs_to :author, Cyanea.Accounts.User
    has_many :comments, Cyanea.Discussions.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(discussion, attrs) do
    discussion
    |> cast(attrs, [:title, :body, :status, :space_id, :author_id])
    |> validate_required([:title, :body, :space_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_inclusion(:status, @statuses)
  end

  def statuses, do: @statuses
end

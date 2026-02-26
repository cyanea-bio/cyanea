defmodule Cyanea.Discussions.Comment do
  @moduledoc """
  Comment schema — comments on discussions, with one-level nesting.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "comments" do
    field :body, :string

    belongs_to :discussion, Cyanea.Discussions.Discussion
    belongs_to :author, Cyanea.Accounts.User
    belongs_to :parent_comment, __MODULE__
    has_many :replies, __MODULE__, foreign_key: :parent_comment_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :discussion_id, :author_id, :parent_comment_id])
    |> validate_required([:body, :discussion_id])
    |> validate_length(:body, min: 1)
  end
end

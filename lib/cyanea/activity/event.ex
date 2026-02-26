defmodule Cyanea.Activity.Event do
  @moduledoc """
  ActivityEvent schema — append-only activity log entry.

  Immutable: has inserted_at but no updated_at.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [inserted_at: :inserted_at, updated_at: false]

  @actions ~w(
    created_space updated_space forked_space starred_space
    created_notebook updated_notebook
    created_protocol updated_protocol
    created_dataset uploaded_file
    created_discussion commented
  )

  @subject_types ~w(space notebook protocol dataset discussion comment)

  schema "activity_events" do
    field :action, :string
    field :subject_type, :string
    field :subject_id, :binary_id
    field :metadata, :map, default: %{}

    belongs_to :actor, Cyanea.Accounts.User
    belongs_to :space, Cyanea.Spaces.Space

    field :inserted_at, :utc_datetime
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:action, :subject_type, :subject_id, :actor_id, :space_id, :metadata])
    |> validate_required([:action, :subject_type, :subject_id])
    |> validate_inclusion(:action, @actions)
    |> validate_inclusion(:subject_type, @subject_types)
    |> put_inserted_at()
  end

  defp put_inserted_at(changeset) do
    if get_field(changeset, :inserted_at) do
      changeset
    else
      put_change(changeset, :inserted_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  def actions, do: @actions
  def subject_types, do: @subject_types
end

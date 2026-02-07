defmodule Cyanea.Artifacts.ArtifactEvent do
  @moduledoc """
  Append-only event log for artifact lifecycle tracking.

  Every significant action on an artifact is recorded as an event,
  providing a complete audit trail and enabling event-sourced projections.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @event_types ~w(created updated derived published unpublished archived deleted version_bumped files_changed)

  schema "artifact_events" do
    field :event_type, :string
    field :payload, :map, default: %{}
    field :inserted_at, :utc_datetime

    belongs_to :artifact, Cyanea.Artifacts.Artifact
    belongs_to :actor, Cyanea.Accounts.User
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_type, :payload, :artifact_id, :actor_id])
    |> validate_required([:event_type, :artifact_id])
    |> validate_inclusion(:event_type, @event_types)
    |> put_timestamp()
  end

  defp put_timestamp(changeset) do
    if get_field(changeset, :inserted_at) do
      changeset
    else
      put_change(changeset, :inserted_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  def event_types, do: @event_types
end

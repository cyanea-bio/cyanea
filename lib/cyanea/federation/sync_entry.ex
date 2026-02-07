defmodule Cyanea.Federation.SyncEntry do
  @moduledoc """
  Tracks individual sync operations to/from federation nodes.

  Each entry records whether a resource was pushed to or pulled from
  a remote node, along with its completion status.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @directions ~w(push pull)
  @statuses ~w(pending in_progress completed failed)
  @resource_types ~w(artifact manifest)

  schema "sync_entries" do
    field :direction, :string
    field :resource_type, :string
    field :resource_id, :binary_id
    field :status, :string, default: "pending"
    field :error_message, :string
    field :inserted_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :node, Cyanea.Federation.Node
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :direction,
      :resource_type,
      :resource_id,
      :status,
      :error_message,
      :node_id,
      :completed_at
    ])
    |> validate_required([:direction, :resource_type, :resource_id, :node_id])
    |> validate_inclusion(:direction, @directions)
    |> validate_inclusion(:resource_type, @resource_types)
    |> validate_inclusion(:status, @statuses)
    |> put_timestamp()
  end

  defp put_timestamp(changeset) do
    if get_field(changeset, :inserted_at) do
      changeset
    else
      put_change(changeset, :inserted_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  def directions, do: @directions
  def statuses, do: @statuses
  def resource_types, do: @resource_types
end

defmodule Cyanea.Federation.Node do
  @moduledoc """
  Federation node schema — represents a remote Cyanea instance.

  Nodes connect to each other for selective artifact publishing,
  discovery mirroring, and cross-node references.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(pending active inactive revoked)

  schema "federation_nodes" do
    field :name, :string
    field :url, :string
    field :public_key, :string
    field :status, :string, default: "pending"
    field :last_sync_at, :utc_datetime
    field :metadata, :map, default: %{}

    has_many :manifests, Cyanea.Federation.Manifest
    has_many :sync_entries, Cyanea.Federation.SyncEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:name, :url, :public_key, :status, :last_sync_at, :metadata])
    |> validate_required([:name, :url])
    |> validate_format(:url, ~r/^https?:\/\//,
      message: "must be a valid HTTP(S) URL"
    )
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:url)
  end

  def statuses, do: @statuses
end

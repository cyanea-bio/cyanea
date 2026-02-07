defmodule Cyanea.Federation.Manifest do
  @moduledoc """
  Signed manifest — an attestation that a specific artifact version
  has been published to the federation network.

  Manifests are content-addressed: the `content_hash` covers the
  artifact's data, and the optional `signature` proves provenance
  via the signer's public key.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "manifests" do
    field :global_id, :string
    field :content_hash, :string
    field :signature, :string
    field :signer_key_id, :string
    field :payload, :map, default: %{}

    belongs_to :artifact, Cyanea.Artifacts.Artifact
    belongs_to :node, Cyanea.Federation.Node

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(manifest, attrs) do
    manifest
    |> cast(attrs, [
      :global_id,
      :content_hash,
      :signature,
      :signer_key_id,
      :payload,
      :artifact_id,
      :node_id
    ])
    |> validate_required([:global_id, :content_hash, :artifact_id])
    |> unique_constraint(:global_id)
  end
end

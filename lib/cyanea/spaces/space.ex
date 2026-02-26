defmodule Cyanea.Spaces.Space do
  @moduledoc """
  Space schema — the top-level container for research content.

  Spaces replace the old Repository/Artifact model. Each space contains
  notebooks, protocols, datasets, and files, with polymorphic ownership
  (user or organization) and append-only revision history.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @visibility ~w(public private)
  @licenses ~w(cc-by-4.0 cc-by-sa-4.0 cc0-1.0 mit apache-2.0 proprietary)
  @owner_types ~w(user organization)

  schema "spaces" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :visibility, :string, default: "private"
    field :license, :string
    field :archived, :boolean, default: false

    # Polymorphic owner
    field :owner_type, :string
    field :owner_id, :binary_id

    # Counters
    field :fork_count, :integer, default: 0
    field :star_count, :integer, default: 0
    field :discussion_count, :integer, default: 0

    # Tagging and ontology
    field :tags, {:array, :string}, default: []
    field :ontology_terms, {:array, :map}, default: []

    # Federation
    field :global_id, :string

    # Forking
    belongs_to :forked_from, __MODULE__

    # Current revision
    belongs_to :current_revision, Cyanea.Revisions.Revision

    # Content types
    has_many :notebooks, Cyanea.Notebooks.Notebook
    has_many :protocols, Cyanea.Protocols.Protocol
    has_many :datasets, Cyanea.Datasets.Dataset
    has_many :space_files, Cyanea.Blobs.SpaceFile
    has_many :revisions, Cyanea.Revisions.Revision
    has_many :stars, Cyanea.Stars.Star
    has_many :discussions, Cyanea.Discussions.Discussion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(space, attrs) do
    space
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :visibility,
      :license,
      :archived,
      :owner_type,
      :owner_id,
      :forked_from_id,
      :fork_count,
      :star_count,
      :tags,
      :ontology_terms,
      :global_id,
      :current_revision_id
    ])
    |> validate_required([:name, :slug, :owner_type, :owner_id])
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9._-]*$/,
      message:
        "must start with a letter/number and contain only lowercase letters, numbers, dots, hyphens, and underscores"
    )
    |> validate_length(:slug, min: 1, max: 100)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_inclusion(:visibility, @visibility)
    |> validate_inclusion(:license, @licenses ++ [nil])
    |> validate_inclusion(:owner_type, @owner_types)
    |> unique_constraint([:slug, :owner_type, :owner_id], name: :spaces_slug_owner_index)
    |> unique_constraint(:global_id)
  end

  def visibilities, do: @visibility
  def licenses, do: @licenses
  def owner_types, do: @owner_types
end

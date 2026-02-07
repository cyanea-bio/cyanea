defmodule Cyanea.Artifacts.Artifact do
  @moduledoc """
  Artifact schema — a typed, versioned scientific object.

  Artifacts are the core domain objects in Cyanea: datasets, protocols,
  notebooks, pipelines, results, and samples. Each artifact belongs to a
  repository, has a version history, and maintains lineage via
  `parent_artifact_id` for derivations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @types ~w(dataset protocol notebook pipeline result sample)
  @visibility ~w(public internal private)

  schema "artifacts" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :type, :string
    field :version, :string, default: "1.0.0"
    field :visibility, :string, default: "private"
    field :license, :string
    field :content_hash, :string
    field :global_id, :string
    field :metadata, :map, default: %{}
    field :tags, {:array, :string}, default: []

    belongs_to :repository, Cyanea.Repositories.Repository
    belongs_to :author, Cyanea.Accounts.User
    belongs_to :parent_artifact, Cyanea.Artifacts.Artifact

    has_many :derived_artifacts, Cyanea.Artifacts.Artifact, foreign_key: :parent_artifact_id
    has_many :events, Cyanea.Artifacts.ArtifactEvent
    has_many :artifact_files, Cyanea.Artifacts.ArtifactFile

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(artifact, attrs) do
    artifact
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :type,
      :version,
      :visibility,
      :license,
      :content_hash,
      :global_id,
      :metadata,
      :tags,
      :repository_id,
      :author_id,
      :parent_artifact_id
    ])
    |> validate_required([:name, :slug, :type, :repository_id, :author_id])
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9._-]*$/,
      message:
        "must start with a letter/number and contain only lowercase letters, numbers, dots, hyphens, and underscores"
    )
    |> validate_length(:slug, min: 1, max: 100)
    |> validate_length(:name, min: 1, max: 200)
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:visibility, @visibility)
    |> validate_format(:version, ~r/^\d+\.\d+\.\d+$/,
      message: "must be a semantic version (e.g. 1.0.0)"
    )
    |> unique_constraint([:slug, :repository_id])
    |> unique_constraint(:global_id)
  end

  def types, do: @types
  def visibilities, do: @visibility
end

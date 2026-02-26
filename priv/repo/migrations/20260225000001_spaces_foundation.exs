defmodule Cyanea.Repo.Migrations.SpacesFoundation do
  use Ecto.Migration

  def change do
    # =========================================================================
    # Drop old tables (in dependency order)
    # =========================================================================

    drop_if_exists table(:artifact_files)
    drop_if_exists table(:artifact_events)
    drop_if_exists table(:manifests)
    drop_if_exists table(:artifacts)
    drop_if_exists table(:files)
    drop_if_exists table(:commits)
    drop_if_exists table(:repositories)

    # =========================================================================
    # Spaces — the top-level container for research content
    # =========================================================================

    create table(:spaces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :visibility, :string, null: false, default: "private"
      add :license, :string
      add :archived, :boolean, null: false, default: false

      # Polymorphic owner (user or organization)
      add :owner_type, :string, null: false
      add :owner_id, :binary_id, null: false

      # Forking
      add :forked_from_id, references(:spaces, type: :binary_id, on_delete: :nilify_all)
      add :fork_count, :integer, null: false, default: 0
      add :star_count, :integer, null: false, default: 0

      # Tagging and ontology
      add :tags, {:array, :string}, default: []
      add :ontology_terms, {:array, :map}, default: []

      # Federation
      add :global_id, :string

      # Current revision pointer (set after revisions table is created)
      add :current_revision_id, :binary_id

      timestamps(type: :utc_datetime)
    end

    create index(:spaces, [:owner_type, :owner_id])
    create index(:spaces, [:visibility])
    create index(:spaces, [:tags])
    create index(:spaces, [:forked_from_id])
    create index(:spaces, [:global_id], unique: true, where: "global_id IS NOT NULL")

    # Unique slug per owner
    create unique_index(:spaces, [:slug, :owner_type, :owner_id],
      name: :spaces_slug_owner_index
    )

    # =========================================================================
    # Blobs — content-addressed, deduplicated file storage
    # =========================================================================

    create table(:blobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sha256, :string, null: false, size: 64
      add :size, :bigint, null: false
      add :mime_type, :string
      add :s3_key, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blobs, [:sha256])
    create index(:blobs, [:mime_type])

    # =========================================================================
    # Space files — files attached directly to a space
    # =========================================================================

    create table(:space_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string, null: false
      add :name, :string, null: false

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :blob_id, references(:blobs, type: :binary_id, on_delete: :restrict),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:space_files, [:space_id])
    create index(:space_files, [:blob_id])
    create unique_index(:space_files, [:space_id, :path])

    # =========================================================================
    # Revisions — immutable, sequential snapshots per space
    # =========================================================================

    create table(:revisions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :integer, null: false
      add :summary, :text
      add :content_hash, :string

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :parent_revision_id,
          references(:revisions, type: :binary_id, on_delete: :nilify_all)

      add :author_id, references(:users, type: :binary_id, on_delete: :nilify_all),
        null: false

      # Immutable — only inserted_at, no updated_at
      add :created_at, :utc_datetime, null: false
    end

    create index(:revisions, [:space_id])
    create index(:revisions, [:author_id])
    create index(:revisions, [:parent_revision_id])
    create unique_index(:revisions, [:space_id, :number])

    # =========================================================================
    # Notebooks — computational notebooks within a space
    # =========================================================================

    create table(:notebooks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :map, default: %{}
      add :position, :integer, null: false, default: 0

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notebooks, [:space_id])
    create unique_index(:notebooks, [:space_id, :slug])

    # =========================================================================
    # Protocols — versioned experimental procedures
    # =========================================================================

    create table(:protocols, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :content, :map, default: %{}
      add :version, :string, null: false, default: "1.0.0"
      add :position, :integer, null: false, default: 0

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:protocols, [:space_id])
    create unique_index(:protocols, [:space_id, :slug])

    # =========================================================================
    # Datasets — structured data collections
    # =========================================================================

    create table(:datasets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :storage_type, :string, null: false, default: "local"
      add :external_url, :string
      add :metadata, :map, default: %{}
      add :tags, {:array, :string}, default: []
      add :position, :integer, null: false, default: 0

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:datasets, [:space_id])
    create unique_index(:datasets, [:space_id, :slug])
    create index(:datasets, [:tags])

    # =========================================================================
    # Dataset files — files belonging to a dataset
    # =========================================================================

    create table(:dataset_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string, null: false
      add :size, :bigint

      add :dataset_id, references(:datasets, type: :binary_id, on_delete: :delete_all),
        null: false

      add :blob_id, references(:blobs, type: :binary_id, on_delete: :restrict),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:dataset_files, [:dataset_id])
    create index(:dataset_files, [:blob_id])
    create unique_index(:dataset_files, [:dataset_id, :path])

    # =========================================================================
    # Stars — user bookmarks on spaces
    # =========================================================================

    create table(:stars, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all),
        null: false

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :inserted_at, :utc_datetime, null: false
    end

    create index(:stars, [:space_id])
    create unique_index(:stars, [:user_id, :space_id])

    # =========================================================================
    # Re-create manifests table pointing to spaces instead of artifacts
    # =========================================================================

    create table(:manifests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :global_id, :string, null: false
      add :content_hash, :string, null: false
      add :signature, :text
      add :signer_key_id, :string
      add :payload, :map, null: false, default: %{}

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all)

      add :node_id, references(:federation_nodes, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:manifests, [:global_id])
    create index(:manifests, [:space_id])
    create index(:manifests, [:node_id])
    create index(:manifests, [:content_hash])
  end
end

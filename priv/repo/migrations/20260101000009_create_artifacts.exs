defmodule Cyanea.Repo.Migrations.CreateArtifacts do
  use Ecto.Migration

  def change do
    create table(:artifacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :type, :string, null: false
      add :version, :string, null: false, default: "1.0.0"
      add :visibility, :string, null: false, default: "private"
      add :license, :string
      add :content_hash, :string
      add :global_id, :string

      # Type-specific metadata stored as JSONB
      add :metadata, :map, default: %{}
      add :tags, {:array, :string}, default: []

      add :repository_id, references(:repositories, type: :binary_id, on_delete: :delete_all),
        null: false

      add :author_id, references(:users, type: :binary_id, on_delete: :nilify_all),
        null: false

      # Self-referencing for derivations / lineage
      add :parent_artifact_id, references(:artifacts, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:artifacts, [:repository_id])
    create index(:artifacts, [:author_id])
    create index(:artifacts, [:parent_artifact_id])
    create index(:artifacts, [:type])
    create index(:artifacts, [:visibility])
    create index(:artifacts, [:content_hash])
    create index(:artifacts, [:global_id], unique: true, where: "global_id IS NOT NULL")
    create index(:artifacts, [:tags])

    # Unique slug per repository
    create unique_index(:artifacts, [:slug, :repository_id],
      name: :artifacts_slug_repository_id_index
    )

    # ---------------------------------------------------------------------------
    # Artifact events — append-only audit trail
    # ---------------------------------------------------------------------------

    create table(:artifact_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_type, :string, null: false
      add :payload, :map, default: %{}

      add :artifact_id, references(:artifacts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :inserted_at, :utc_datetime, null: false
    end

    create index(:artifact_events, [:artifact_id])
    create index(:artifact_events, [:actor_id])
    create index(:artifact_events, [:event_type])
    create index(:artifact_events, [:inserted_at])

    # ---------------------------------------------------------------------------
    # Artifact–File join table — links artifacts to their constituent files
    # ---------------------------------------------------------------------------

    create table(:artifact_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string, null: false

      add :artifact_id, references(:artifacts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :file_id, references(:files, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:artifact_files, [:artifact_id])
    create index(:artifact_files, [:file_id])
    create unique_index(:artifact_files, [:artifact_id, :path])
  end
end

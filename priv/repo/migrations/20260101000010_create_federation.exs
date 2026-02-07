defmodule Cyanea.Repo.Migrations.CreateFederation do
  use Ecto.Migration

  def change do
    # ---------------------------------------------------------------------------
    # Federation nodes — other Cyanea instances we sync with
    # ---------------------------------------------------------------------------

    create table(:federation_nodes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :url, :string, null: false
      add :public_key, :text
      add :status, :string, null: false, default: "pending"
      add :last_sync_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:federation_nodes, [:url])
    create index(:federation_nodes, [:status])

    # ---------------------------------------------------------------------------
    # Signed manifests — attestations of published artifacts
    # ---------------------------------------------------------------------------

    create table(:manifests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :global_id, :string, null: false
      add :content_hash, :string, null: false
      add :signature, :text
      add :signer_key_id, :string
      add :payload, :map, null: false, default: %{}

      add :artifact_id, references(:artifacts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :node_id, references(:federation_nodes, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:manifests, [:global_id])
    create index(:manifests, [:artifact_id])
    create index(:manifests, [:node_id])
    create index(:manifests, [:content_hash])

    # ---------------------------------------------------------------------------
    # Sync log — tracks what has been synced to/from each node
    # ---------------------------------------------------------------------------

    create table(:sync_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :direction, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :binary_id, null: false
      add :status, :string, null: false, default: "pending"
      add :error_message, :text

      add :node_id, references(:federation_nodes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :inserted_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
    end

    create index(:sync_entries, [:node_id])
    create index(:sync_entries, [:resource_type, :resource_id])
    create index(:sync_entries, [:status])
    create index(:sync_entries, [:direction])
  end
end

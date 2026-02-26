defmodule Cyanea.Repo.Migrations.AddFederationFeatures do
  use Ecto.Migration

  def change do
    # Add federation_policy to spaces
    alter table(:spaces) do
      add :federation_policy, :string, default: "none", null: false
    end

    # Add retry and bandwidth tracking to sync_entries
    alter table(:sync_entries) do
      add :retries, :integer, default: 0, null: false
      add :max_retries, :integer, default: 5, null: false
      add :next_retry_at, :utc_datetime
      add :bytes_transferred, :bigint, default: 0
    end

    # Add published_at to manifests for tracking publish/unpublish
    alter table(:manifests) do
      add :status, :string, default: "published", null: false
      add :retracted_reason, :string
      add :revision_number, :integer
    end

    # Create index for finding published spaces
    create index(:spaces, [:federation_policy], where: "federation_policy != 'none'")

    # Create index for retry scheduling
    create index(:sync_entries, [:status, :next_retry_at],
             where: "status = 'pending' OR status = 'failed'")
  end
end

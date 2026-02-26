defmodule Cyanea.Repo.Migrations.Phase9Api do
  use Ecto.Migration

  def change do
    # API tokens for programmatic access
    create table(:api_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :token_prefix, :string, null: false
      add :token_hash, :string, null: false
      add :scopes, {:array, :string}, null: false, default: ["read"]
      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime
      add :revoked_at, :utc_datetime

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:api_tokens, [:user_id])
    create unique_index(:api_tokens, [:token_hash])
    create index(:api_tokens, [:token_prefix])

    # Webhooks for event notifications
    create table(:webhooks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string, null: false
      add :secret, :string, null: false
      add :events, {:array, :string}, null: false
      add :active, :boolean, null: false, default: true
      add :description, :string

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:webhooks, [:user_id])
    create index(:webhooks, [:space_id])

    # Webhook delivery log
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event, :string, null: false
      add :payload, :map, null: false
      add :response_status, :integer
      add :response_body, :text
      add :status, :string, null: false, default: "pending"
      add :attempts, :integer, null: false, default: 0
      add :completed_at, :utc_datetime

      add :webhook_id, references(:webhooks, type: :binary_id, on_delete: :delete_all),
        null: false

      add :inserted_at, :utc_datetime, null: false, default: fragment("(datetime('now'))")
    end

    create index(:webhook_deliveries, [:webhook_id])
    create index(:webhook_deliveries, [:status])
    create index(:webhook_deliveries, [:inserted_at])
  end
end

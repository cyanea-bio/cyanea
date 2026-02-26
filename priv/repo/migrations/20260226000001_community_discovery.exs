defmodule Cyanea.Repo.Migrations.CommunityDiscovery do
  use Ecto.Migration

  def change do
    # ── Discussions ──────────────────────────────────────────────────────────
    create table(:discussions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all), null: false
      add :author_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :title, :string, null: false
      add :body, :text, null: false
      add :status, :string, default: "open", null: false
      add :comment_count, :integer, default: 0
      timestamps(type: :utc_datetime)
    end

    create index(:discussions, [:space_id])
    create index(:discussions, [:author_id])

    # ── Comments (one-level nesting via parent_comment_id) ───────────────────
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :discussion_id, references(:discussions, type: :binary_id, on_delete: :delete_all),
        null: false

      add :author_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :body, :text, null: false
      add :parent_comment_id, references(:comments, type: :binary_id, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:discussion_id])
    create index(:comments, [:parent_comment_id])

    # ── Activity Events (append-only log) ────────────────────────────────────
    create table(:activity_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :action, :string, null: false
      add :subject_type, :string, null: false
      add :subject_id, :binary_id, null: false
      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all)
      add :metadata, :map, default: %{}
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:activity_events, [:actor_id, :inserted_at])
    create index(:activity_events, [:space_id, :inserted_at])
    create index(:activity_events, [:inserted_at])

    # ── Follows (user follows user or organization) ──────────────────────────
    create table(:follows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :follower_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :followed_type, :string, null: false
      add :followed_id, :binary_id, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:follows, [:follower_id, :followed_type, :followed_id])
    create index(:follows, [:followed_type, :followed_id])

    # ── Notifications ────────────────────────────────────────────────────────
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :action, :string, null: false
      add :subject_type, :string, null: false
      add :subject_id, :binary_id, null: false
      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all)
      add :read_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id, :read_at, :inserted_at])

    # ── Add discussion_count to spaces ───────────────────────────────────────
    alter table(:spaces) do
      add :discussion_count, :integer, default: 0
    end
  end
end

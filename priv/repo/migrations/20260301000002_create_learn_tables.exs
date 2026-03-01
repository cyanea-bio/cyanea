defmodule Cyanea.Repo.Migrations.CreateLearnTables do
  use Ecto.Migration

  def change do
    create table(:learn_tracks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :position, :integer, null: false, default: 0
      add :published, :boolean, null: false, default: false
      add :icon, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:learn_tracks, [:slug])

    create table(:learn_paths, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :position, :integer, null: false, default: 0
      add :published, :boolean, null: false, default: false

      add :track_id, references(:learn_tracks, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:learn_paths, [:track_id])
    create unique_index(:learn_paths, [:track_id, :slug])

    create table(:learn_path_units, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :position, :integer, null: false, default: 0
      add :estimated_minutes, :integer

      add :path_id, references(:learn_paths, type: :binary_id, on_delete: :delete_all),
        null: false

      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:learn_path_units, [:path_id])
    create index(:learn_path_units, [:space_id])
    create unique_index(:learn_path_units, [:path_id, :space_id])

    create table(:learn_prerequisites, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :unit_space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :prerequisite_space_id, references(:spaces, type: :binary_id, on_delete: :delete_all),
        null: false

      add :inserted_at, :utc_datetime,
        null: false,
        default:
          if(Cyanea.DB.sqlite?(),
            do: fragment("(datetime('now'))"),
            else: fragment("NOW()")
          )
    end

    create unique_index(:learn_prerequisites, [:unit_space_id, :prerequisite_space_id])

    create table(:learn_progress, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, null: false, default: "not_started"
      add :checkpoints_total, :integer, null: false, default: 0
      add :checkpoints_passed, :integer, null: false, default: 0
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :space_id, references(:spaces, type: :binary_id, on_delete: :delete_all), null: false

      add :fork_space_id, references(:spaces, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:learn_progress, [:user_id])
    create index(:learn_progress, [:space_id])
    create unique_index(:learn_progress, [:user_id, :space_id])

    create table(:learn_achievements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :achievement_type, :string, null: false
      add :achievement_key, :string, null: false
      add :metadata, :map, default: %{}
      add :earned_at, :utc_datetime, null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:learn_achievements, [:user_id])
    create unique_index(:learn_achievements, [:user_id, :achievement_type, :achievement_key])
  end
end

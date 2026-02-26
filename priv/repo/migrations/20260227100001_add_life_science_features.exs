defmodule Cyanea.Repo.Migrations.AddLifeScienceFeatures do
  use Ecto.Migration

  def change do
    # File preview cache table
    create table(:file_previews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :blob_id, references(:blobs, type: :binary_id, on_delete: :delete_all), null: false
      add :preview_type, :string, null: false
      add :preview_data, :map, default: %{}
      add :generated_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:file_previews, [:blob_id])

    # DOI field on spaces
    alter table(:spaces) do
      add :doi, :string
    end
  end
end

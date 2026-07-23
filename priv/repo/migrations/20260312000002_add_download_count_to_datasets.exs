defmodule Cyanea.Repo.Migrations.AddDownloadCountToDatasets do
  use Ecto.Migration

  def change do
    alter table(:datasets) do
      add :download_count, :integer, default: 0, null: false
    end
  end
end

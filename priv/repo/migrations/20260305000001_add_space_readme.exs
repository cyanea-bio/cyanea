defmodule Cyanea.Repo.Migrations.AddSpaceReadme do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :readme, :text
    end
  end
end

defmodule Cyanea.Repo.Migrations.AddSpaceType do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :space_type, :string, null: false, default: "default"
    end

    create index(:spaces, [:space_type])
  end
end

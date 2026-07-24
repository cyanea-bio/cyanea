defmodule Cyanea.Repo.Migrations.AddReadmeToUsersAndOrganizations do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :readme, :text
    end

    alter table(:organizations) do
      add :readme, :text
    end
  end
end

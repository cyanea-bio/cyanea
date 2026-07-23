defmodule Cyanea.Repo.Migrations.AddServiceAccountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :service_account, :boolean, default: false, null: false
    end
  end
end

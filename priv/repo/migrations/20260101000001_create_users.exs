defmodule Cyanea.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :username, :string, null: false
      add :name, :string
      add :password_hash, :string
      add :orcid_id, :string
      add :avatar_url, :string
      add :bio, :text
      add :affiliation, :string
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create unique_index(:users, [:orcid_id], where: "orcid_id IS NOT NULL")

  end
end

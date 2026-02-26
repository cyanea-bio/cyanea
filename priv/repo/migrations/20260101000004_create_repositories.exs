defmodule Cyanea.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :visibility, :string, null: false, default: "private"
      add :license, :string
      add :default_branch, :string, default: "main"
      add :stars_count, :integer, default: 0, null: false
      add :forks_count, :integer, default: 0, null: false
      add :archived, :boolean, default: false, null: false
      add :tags, {:array, :string}, default: []
      add :ontology_terms, {:array, :map}, default: []

      # Either owner_id OR organization_id must be set (not both)
      add :owner_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:repositories, [:owner_id])
    create index(:repositories, [:organization_id])
    create index(:repositories, [:visibility])
    create index(:repositories, [:tags])

    # Unique slug per owner
    create unique_index(:repositories, [:slug, :owner_id],
      where: "owner_id IS NOT NULL",
      name: :repositories_slug_owner_id_index)

    # Unique slug per organization
    create unique_index(:repositories, [:slug, :organization_id],
      where: "organization_id IS NOT NULL",
      name: :repositories_slug_organization_id_index)
  end
end

defmodule Cyanea.Repo.Migrations.CreateObanTables do
  use Ecto.Migration

  def up do
    Oban.Migrations.SQLite.up(version: 2)
  end

  def down do
    Oban.Migrations.SQLite.down(version: 2)
  end
end

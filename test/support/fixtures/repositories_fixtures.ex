defmodule Cyanea.RepositoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cyanea.Repositories` context.
  """

  def unique_repo_name, do: "repo-#{System.unique_integer([:positive])}"
  def unique_repo_slug, do: "repo-#{System.unique_integer([:positive])}"

  def valid_repo_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_repo_name(),
      slug: unique_repo_slug(),
      description: "A test repository",
      visibility: "public"
    })
  end

  def repository_fixture(attrs \\ %{}) do
    attrs = valid_repo_attributes(attrs)

    unless Map.has_key?(attrs, :owner_id) || Map.has_key?(attrs, :organization_id) do
      raise "repository_fixture requires :owner_id or :organization_id"
    end

    {:ok, repository} = Cyanea.Repositories.create_repository(attrs)
    repository
  end
end

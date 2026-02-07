defmodule Cyanea.ArtifactsFixtures do
  @moduledoc """
  Test helpers for creating entities via the `Cyanea.Artifacts` context.
  """

  def unique_artifact_name, do: "artifact-#{System.unique_integer([:positive])}"
  def unique_artifact_slug, do: "artifact-#{System.unique_integer([:positive])}"

  def valid_artifact_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_artifact_name(),
      slug: unique_artifact_slug(),
      description: "A test artifact",
      type: "dataset",
      version: "1.0.0",
      visibility: "public"
    })
  end

  def artifact_fixture(attrs \\ %{}) do
    attrs = valid_artifact_attributes(attrs)

    unless Map.has_key?(attrs, :repository_id) && Map.has_key?(attrs, :author_id) do
      raise "artifact_fixture requires :repository_id and :author_id"
    end

    {:ok, artifact} = Cyanea.Artifacts.create_artifact(attrs)
    artifact
  end
end

defmodule Cyanea.LearnFixtures do
  @moduledoc """
  Test fixtures for the Learn context.
  """

  alias Cyanea.Learn

  def unique_track_title, do: "Track #{System.unique_integer([:positive])}"
  def unique_track_slug, do: "track-#{System.unique_integer([:positive])}"

  def unique_path_title, do: "Path #{System.unique_integer([:positive])}"
  def unique_path_slug, do: "path-#{System.unique_integer([:positive])}"

  def valid_track_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: unique_track_title(),
      slug: unique_track_slug(),
      description: "A test track",
      position: 0,
      published: true
    })
  end

  def track_fixture(attrs \\ %{}) do
    attrs = valid_track_attributes(attrs)
    {:ok, track} = Learn.create_track(attrs)
    track
  end

  def valid_path_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: unique_path_title(),
      slug: unique_path_slug(),
      description: "A test path",
      position: 0,
      published: true
    })
  end

  def path_fixture(attrs \\ %{}) do
    attrs = valid_path_attributes(attrs)

    unless Map.has_key?(attrs, :track_id) do
      raise "path_fixture requires :track_id"
    end

    {:ok, path} = Learn.create_path(attrs)
    path
  end
end

defmodule Mix.Tasks.Search.Reindex do
  @moduledoc """
  Reindexes all searchable content in Meilisearch.

  ## Usage

      mix search.reindex
  """
  use Mix.Task

  @shortdoc "Reindexes all content in Meilisearch"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    Mix.shell().info("Setting up indexes...")
    Cyanea.Search.setup_indexes()

    Mix.shell().info("Reindexing repositories...")
    Cyanea.Search.reindex_all_repositories()

    Mix.shell().info("Reindexing users...")
    Cyanea.Search.reindex_all_users()

    Mix.shell().info("Done!")
  end
end

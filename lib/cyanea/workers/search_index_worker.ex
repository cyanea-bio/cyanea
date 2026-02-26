defmodule Cyanea.Workers.SearchIndexWorker do
  @moduledoc """
  Async Meilisearch indexing for spaces and users.

  Decouples search indexing from the request cycle so that creates,
  updates, and deletes don't block on Meilisearch availability.

  ## Usage

      # Index a space
      %{type: "space", id: space_id, action: "index"}
      |> Cyanea.Workers.SearchIndexWorker.new()
      |> Oban.insert()

      # Delete a user from the index
      %{type: "user", id: user_id, action: "delete"}
      |> Cyanea.Workers.SearchIndexWorker.new()
      |> Oban.insert()
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 5,
    unique: [period: 30, keys: [:type, :id, :action]]

  alias Cyanea.Search

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "space", "id" => id, "action" => "index"}}) do
    space = Cyanea.Spaces.get_space!(id)
    Search.index_space(space)
    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "space", "id" => id, "action" => "delete"}}) do
    Search.delete_space(id)
    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "user", "id" => id, "action" => "index"}}) do
    case Cyanea.Accounts.get_user(id) do
      nil -> :ok
      user -> Search.index_user(user)
    end

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "user", "id" => id, "action" => "delete"}}) do
    Search.delete_user(id)
    :ok
  end
end

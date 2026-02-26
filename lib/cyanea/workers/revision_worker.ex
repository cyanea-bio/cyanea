defmodule Cyanea.Workers.RevisionWorker do
  @moduledoc """
  Async revision snapshot creation for spaces.

  Computes a content hash from the space's current files and creates
  an immutable revision record. Useful after batch uploads or edits
  where creating a revision inline would slow the request.

  ## Usage

      %{space_id: space_id, author_id: user_id, summary: "Added dataset files"}
      |> Cyanea.Workers.RevisionWorker.new()
      |> Oban.insert()
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [period: 10, keys: [:space_id]]

  alias Cyanea.Blobs
  alias Cyanea.Hash
  alias Cyanea.Revisions

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"space_id" => space_id, "author_id" => author_id} = args}) do
    summary = Map.get(args, "summary", "Auto-generated revision")
    content_hash = compute_content_hash(space_id)

    case Revisions.create_revision(%{
           space_id: space_id,
           author_id: author_id,
           summary: summary,
           content_hash: content_hash
         }) do
      {:ok, _revision} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp compute_content_hash(space_id) do
    files = Blobs.list_space_files(space_id)

    files
    |> Enum.sort_by(& &1.path)
    |> Enum.map_join("\n", fn sf -> "#{sf.path}:#{sf.blob.sha256}" end)
    |> Hash.sha256()
  end
end

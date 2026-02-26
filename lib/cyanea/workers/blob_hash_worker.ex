defmodule Cyanea.Workers.BlobHashWorker do
  @moduledoc """
  Async SHA-256 computation and blob creation from uploaded files.

  Handles the full upload pipeline in the background:
  1. Read file from temp path
  2. Compute SHA-256 hash
  3. Find or create deduplicated blob
  4. Upload to S3 (if new)
  5. Attach to space as a space file

  ## Usage

      %{path: tmp_path, space_id: space_id, name: filename, mime_type: mime}
      |> Cyanea.Workers.BlobHashWorker.new()
      |> Oban.insert()
  """
  use Oban.Worker, queue: :uploads, max_attempts: 3

  alias Cyanea.Blobs
  alias Cyanea.Hash

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"path" => path, "space_id" => space_id, "name" => name} = args}) do
    mime_type = Map.get(args, "mime_type", "application/octet-stream")

    with {:ok, sha256} <- compute_hash(path),
         {:ok, blob} <- ensure_blob(path, sha256, mime_type),
         {:ok, _sf} <- Blobs.attach_file_to_space(space_id, blob.id, name, name) do
      :ok
    end
  end

  defp compute_hash(path) do
    case Hash.sha256_file(path) do
      {:ok, sha256} -> {:ok, sha256}
      sha256 when is_binary(sha256) -> {:ok, sha256}
    end
  end

  defp ensure_blob(path, sha256, mime_type) do
    binary = File.read!(path)

    case Blobs.find_or_create_blob(sha256, byte_size(binary), mime_type) do
      {:existing, blob} ->
        {:ok, blob}

      {:new, blob} ->
        case Cyanea.Storage.upload(binary, blob.s3_key, content_type: mime_type) do
          {:ok, _} -> {:ok, blob}
          {:error, reason} -> {:error, reason}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end

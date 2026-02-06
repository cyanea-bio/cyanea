defmodule Cyanea.Files do
  @moduledoc """
  The Files context - managing files within repositories.
  """
  import Ecto.Query

  alias Cyanea.Repo
  alias Cyanea.Files.File, as: RepoFile
  alias Cyanea.Hash
  alias Cyanea.Storage

  @doc """
  Lists all files in a repository, ordered by type desc (directories first), then name.
  """
  def list_repository_files(repo_id) do
    from(f in RepoFile,
      where: f.repository_id == ^repo_id,
      order_by: [desc: f.type, asc: f.name]
    )
    |> Repo.all()
  end

  @doc """
  Lists files at a given path prefix within a repository.
  Use `""` or `nil` for root-level files.
  """
  def list_files_at_path(repo_id, prefix) do
    prefix = normalize_prefix(prefix)

    from(f in RepoFile,
      where: f.repository_id == ^repo_id,
      where: f.path == ^prefix or like(f.path, ^"#{prefix}%"),
      order_by: [desc: f.type, asc: f.name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a file by ID. Raises if not found.
  """
  def get_file!(id), do: Repo.get!(RepoFile, id)

  @doc """
  Gets a file by repository ID and path.
  """
  def get_file_by_path(repo_id, path) do
    Repo.get_by(RepoFile, repository_id: repo_id, path: path)
  end

  @doc """
  Creates a file from binary data: computes SHA256, uploads to S3, inserts DB record.
  """
  def create_file(binary, attrs) when is_binary(binary) do
    sha256 = Hash.sha256(binary)
    repo_id = attrs[:repository_id] || attrs["repository_id"]
    path = attrs[:path] || attrs["path"]
    s3_key = Storage.generate_s3_key(repo_id, path)

    with {:ok, _} <- Storage.upload(binary, s3_key, content_type: attrs[:mime_type] || "application/octet-stream") do
      %RepoFile{}
      |> RepoFile.changeset(
        Map.merge(attrs, %{
          sha256: sha256,
          s3_key: s3_key,
          size: byte_size(binary)
        })
      )
      |> Repo.insert()
    end
  end

  @doc """
  Creates a file from an upload temp path.
  """
  def create_file_from_upload(tmp_path, attrs) do
    binary = File.read!(tmp_path)
    create_file(binary, attrs)
  end

  @doc """
  Returns a presigned download URL for a file.
  """
  def download_url(%RepoFile{s3_key: s3_key}) do
    Storage.presigned_download_url(s3_key)
  end

  @doc """
  Deletes a file from S3 and the database.
  """
  def delete_file(%RepoFile{} = file) do
    with {:ok, _} <- Storage.delete(file.s3_key) do
      Repo.delete(file)
    end
  end

  defp normalize_prefix(nil), do: ""
  defp normalize_prefix(""), do: ""
  defp normalize_prefix(prefix), do: String.trim_trailing(prefix, "/") <> "/"
end

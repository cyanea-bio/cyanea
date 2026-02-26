defmodule Cyanea.Storage do
  @moduledoc """
  S3-compatible storage wrapper using ExAws.
  """

  @doc """
  Returns the configured S3 bucket name.
  """
  def bucket do
    Application.get_env(:cyanea, :s3_bucket, "cyanea-dev")
  end

  @doc """
  Creates the bucket if it doesn't exist. Idempotent.
  """
  def ensure_bucket! do
    case ExAws.S3.head_bucket(bucket()) |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, _} ->
        ExAws.S3.put_bucket(bucket(), ExAws.Config.new(:s3).region) |> ExAws.request!()
        :ok
    end
  end

  @doc """
  Uploads binary data to S3.
  """
  def upload(data, s3_key, opts \\ []) when is_binary(data) do
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    ExAws.S3.put_object(bucket(), s3_key, data, content_type: content_type)
    |> ExAws.request()
  end

  @doc """
  Returns a presigned download URL (1 hour expiry).
  """
  def presigned_download_url(s3_key) do
    ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, bucket(), s3_key, expires_in: 3600)
  end

  @doc """
  Downloads an object from S3. Returns `{:ok, binary}` or `{:error, reason}`.
  """
  def download(s3_key) do
    ExAws.S3.get_object(bucket(), s3_key)
    |> ExAws.request()
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes an object from S3.
  """
  def delete(s3_key) do
    ExAws.S3.delete_object(bucket(), s3_key)
    |> ExAws.request()
  end

  @doc """
  Generates an S3 key for a space file (legacy path layout).
  """
  def generate_s3_key(space_id, path) do
    "spaces/#{space_id}/#{path}"
  end

  @doc """
  Generates a content-addressed S3 key for a blob.
  Layout: `blobs/<first-2-chars>/<next-2-chars>/<full-sha256>`
  """
  def generate_blob_s3_key(sha256) do
    prefix1 = String.slice(sha256, 0, 2)
    prefix2 = String.slice(sha256, 2, 2)
    "blobs/#{prefix1}/#{prefix2}/#{sha256}"
  end
end

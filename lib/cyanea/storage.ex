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
  Deletes an object from S3.
  """
  def delete(s3_key) do
    ExAws.S3.delete_object(bucket(), s3_key)
    |> ExAws.request()
  end

  @doc """
  Generates an S3 key for a repository file.
  """
  def generate_s3_key(repo_id, path) do
    "repos/#{repo_id}/#{path}"
  end
end

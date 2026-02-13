defmodule Cyanea.Core do
  @moduledoc "Hashing and compression utilities."

  import Cyanea.NifHelper
  alias Cyanea.Native

  @doc "SHA256 hash of binary data."
  @spec sha256(binary()) :: {:ok, binary()} | {:error, term()}
  def sha256(data) when is_binary(data),
    do: nif_call(fn -> Native.sha256(data) end)

  @doc "SHA256 hash of a file."
  @spec sha256_file(binary()) :: {:ok, binary()} | {:error, term()}
  def sha256_file(path) when is_binary(path),
    do: nif_call(fn -> Native.sha256_file(path) end)

  @doc """
  Compress data using zstd.

  ## Options

    * `:level` - compression level 1-22 (default: 3)

  """
  @spec zstd_compress(binary(), keyword()) :: {:ok, binary()} | {:error, term()}
  def zstd_compress(data, opts \\ []) when is_binary(data) do
    level = Keyword.get(opts, :level, 3)
    nif_call(fn -> Native.zstd_compress(data, level) end)
  end

  @doc "Decompress zstd data."
  @spec zstd_decompress(binary()) :: {:ok, binary()} | {:error, term()}
  def zstd_decompress(data) when is_binary(data),
    do: nif_call(fn -> Native.zstd_decompress(data) end)

  @doc """
  Compress data using gzip.

  ## Options

    * `:level` - compression level 0-9 (default: 6)

  """
  @spec gzip_compress(binary(), keyword()) :: {:ok, binary()} | {:error, term()}
  def gzip_compress(data, opts \\ []) when is_binary(data) do
    level = Keyword.get(opts, :level, 6)
    nif_call(fn -> Native.gzip_compress(data, level) end)
  end

  @doc "Decompress gzip data."
  @spec gzip_decompress(binary()) :: {:ok, binary()} | {:error, term()}
  def gzip_decompress(data) when is_binary(data),
    do: nif_call(fn -> Native.gzip_decompress(data) end)
end

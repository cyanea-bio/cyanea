defmodule Cyanea.Hash do
  @moduledoc """
  Pure Elixir SHA256 hashing via `:crypto`.
  Used when the NIF crate has `skip_compilation?: true`.
  """

  @chunk_size 2 * 1024 * 1024

  @doc """
  Returns the SHA256 hex digest of a binary.
  """
  def sha256(data) when is_binary(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  @doc """
  Streams a file in 2MB chunks and returns `{:ok, hex_digest}`.
  """
  def sha256_file(path) when is_binary(path) do
    hash =
      File.stream!(path, @chunk_size)
      |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, acc ->
        :crypto.hash_update(acc, chunk)
      end)
      |> :crypto.hash_final()
      |> Base.encode16(case: :lower)

    {:ok, hash}
  end
end

defmodule Cyanea.Hash do
  @moduledoc """
  SHA256 hashing with NIF acceleration and pure-Elixir fallback.

  Attempts to use the Rust NIF via `Cyanea.Native.sha256/1` first.
  Falls back to `:crypto` when NIFs are not loaded (e.g. during dev
  with `skip_compilation?: true`).
  """

  @chunk_size 2 * 1024 * 1024

  @doc """
  Returns the SHA256 hex digest of a binary.
  Uses Rust NIF when available, falls back to `:crypto`.
  """
  def sha256(data) when is_binary(data) do
    try do
      Cyanea.Native.sha256(data)
    rescue
      ErlangError -> sha256_fallback(data)
    end
  end

  @doc """
  Streams a file and returns `{:ok, hex_digest}`.
  Uses Rust NIF when available, falls back to `:crypto`.
  """
  def sha256_file(path) when is_binary(path) do
    try do
      Cyanea.Native.sha256_file(path)
    rescue
      ErlangError -> sha256_file_fallback(path)
    end
  end

  # Pure Elixir fallbacks using :crypto

  defp sha256_fallback(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp sha256_file_fallback(path) do
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

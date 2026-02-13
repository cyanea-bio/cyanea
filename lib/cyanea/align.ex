defmodule Cyanea.Align do
  @moduledoc "Pairwise and multiple sequence alignment."

  import Cyanea.NifHelper
  alias Cyanea.Native

  # ===========================================================================
  # Pairwise DNA
  # ===========================================================================

  @doc """
  Align two DNA sequences.

  ## Options

    * `:mode` - `:local` (default), `:global`, or `:semiglobal`
    * `:match` - match score (triggers custom scoring when any scoring opt is present)
    * `:mismatch` - mismatch penalty
    * `:gap_open` - gap open penalty
    * `:gap_extend` - gap extend penalty

  When no scoring options are given, uses defaults (+2/-1/-5/-2).
  """
  @spec dna(binary(), binary(), keyword()) :: {:ok, struct()} | {:error, term()}
  def dna(query, target, opts \\ []) when is_binary(query) and is_binary(target) do
    mode = mode_string(Keyword.get(opts, :mode, :local))

    if has_scoring_opts?(opts) do
      match = Keyword.get(opts, :match, 2)
      mismatch = Keyword.get(opts, :mismatch, -1)
      gap_open = Keyword.get(opts, :gap_open, -5)
      gap_extend = Keyword.get(opts, :gap_extend, -2)
      nif_call(fn -> Native.align_dna_custom(query, target, mode, match, mismatch, gap_open, gap_extend) end)
    else
      nif_call(fn -> Native.align_dna(query, target, mode) end)
    end
  end

  defp has_scoring_opts?(opts) do
    Keyword.has_key?(opts, :match) or Keyword.has_key?(opts, :mismatch) or
      Keyword.has_key?(opts, :gap_open) or Keyword.has_key?(opts, :gap_extend)
  end

  # ===========================================================================
  # Pairwise protein
  # ===========================================================================

  @doc """
  Align two protein sequences.

  ## Options

    * `:mode` - `:global` (default), `:local`, or `:semiglobal`
    * `:matrix` - `:blosum62` (default), `:blosum45`, `:blosum80`, or `:pam250`

  """
  @spec protein(binary(), binary(), keyword()) :: {:ok, struct()} | {:error, term()}
  def protein(query, target, opts \\ []) when is_binary(query) and is_binary(target) do
    mode = mode_string(Keyword.get(opts, :mode, :global))
    matrix = matrix_string(Keyword.get(opts, :matrix, :blosum62))
    nif_call(fn -> Native.align_protein(query, target, mode, matrix) end)
  end

  # ===========================================================================
  # Batch
  # ===========================================================================

  @doc """
  Batch-align a list of `{query, target}` DNA pairs (DirtyCpu scheduler).

  ## Options

    * `:mode` - `:local` (default), `:global`, or `:semiglobal`

  """
  @spec batch(list(), keyword()) :: {:ok, list()} | {:error, term()}
  def batch(pairs, opts \\ []) when is_list(pairs) do
    mode = mode_string(Keyword.get(opts, :mode, :local))
    nif_call(fn -> Native.align_batch_dna(pairs, mode) end)
  end

  # ===========================================================================
  # MSA
  # ===========================================================================

  @doc """
  Progressive multiple sequence alignment.

  ## Options

    * `:mode` - `:dna` (default) or `:protein`

  """
  @spec msa(list(), keyword()) :: {:ok, struct()} | {:error, term()}
  def msa(sequences, opts \\ []) when is_list(sequences) do
    mode = msa_mode_string(Keyword.get(opts, :mode, :dna))
    nif_call(fn -> Native.progressive_msa(sequences, mode) end)
  end

  # ===========================================================================
  # Banded alignment
  # ===========================================================================

  @doc """
  Banded DNA alignment. Restricts DP to diagonal band of `2*bandwidth+1`.

  ## Options

    * `:mode` - `:global` (default), `:local`, or `:semiglobal`
    * `:bandwidth` - band half-width (default: 50)

  """
  @spec banded(binary(), binary(), keyword()) :: {:ok, struct()} | {:error, term()}
  def banded(query, target, opts \\ []) when is_binary(query) and is_binary(target) do
    mode = mode_string(Keyword.get(opts, :mode, :global))
    bandwidth = Keyword.get(opts, :bandwidth, 50)
    nif_call(fn -> Native.banded_align_dna(query, target, mode, bandwidth) end)
  end

  @doc """
  Banded alignment score only (no traceback, less memory).

  ## Options

    * `:mode` - `:global` (default), `:local`, or `:semiglobal`
    * `:bandwidth` - band half-width (default: 50)

  """
  @spec banded_score(binary(), binary(), keyword()) :: {:ok, integer()} | {:error, term()}
  def banded_score(query, target, opts \\ []) when is_binary(query) and is_binary(target) do
    mode = mode_string(Keyword.get(opts, :mode, :global))
    bandwidth = Keyword.get(opts, :bandwidth, 50)
    nif_call(fn -> Native.banded_score_only(query, target, mode, bandwidth) end)
  end

  # ===========================================================================
  # POA consensus
  # ===========================================================================

  @doc "Compute consensus from multiple sequences using Partial Order Alignment."
  @spec consensus(list()) :: {:ok, binary()} | {:error, term()}
  def consensus(sequences) when is_list(sequences),
    do: nif_call(fn -> Native.poa_consensus(sequences) end)
end

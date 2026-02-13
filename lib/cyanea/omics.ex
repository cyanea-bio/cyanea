defmodule Cyanea.Omics do
  @moduledoc "Genomic variants, intervals, and expression matrices."

  import Cyanea.NifHelper
  alias Cyanea.Native

  @doc "Classify a genomic variant (SNV, insertion, deletion, etc.)."
  @spec classify_variant(binary(), integer(), binary(), list()) :: {:ok, struct()} | {:error, term()}
  def classify_variant(chrom, position, ref, alts),
    do: nif_call(fn -> Native.classify_variant(chrom, position, ref, alts) end)

  @doc "Merge overlapping genomic intervals. Takes parallel arrays of chrom, start, end."
  @spec merge_intervals(list(), list(), list()) :: {:ok, list()} | {:error, term()}
  def merge_intervals(chroms, starts, ends)
      when is_list(chroms) and is_list(starts) and is_list(ends),
      do: nif_call(fn -> Native.merge_genomic_intervals(chroms, starts, ends) end)

  @doc "Total bases covered on a chromosome after merging overlaps."
  @spec coverage(list(), list(), list(), binary()) :: {:ok, integer()} | {:error, term()}
  def coverage(chroms, starts, ends, query_chrom),
    do: nif_call(fn -> Native.genomic_coverage(chroms, starts, ends, query_chrom) end)

  @doc "Compute expression matrix summary statistics."
  @spec expression_summary(list(), list(), list()) :: {:ok, struct()} | {:error, term()}
  def expression_summary(data, features, samples),
    do: nif_call(fn -> Native.expression_summary(data, features, samples) end)

  @doc """
  Log2-transform a matrix: log2(x + pseudocount).

  ## Options

    * `:pseudocount` - value added before log (default: 1.0)

  """
  @spec log_transform(list(), keyword()) :: {:ok, list()} | {:error, term()}
  def log_transform(data, opts \\ []) do
    pseudocount = Keyword.get(opts, :pseudocount, 1.0)
    nif_call(fn -> Native.log_transform_matrix(data, pseudocount) end)
  end
end

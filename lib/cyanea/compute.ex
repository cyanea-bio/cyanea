defmodule Cyanea.Compute do
  @moduledoc """
  High-level compute functions backed by Rust NIFs.

  Wraps `Cyanea.Native` with ergonomic APIs for sequence analysis,
  alignment, statistics, and omics operations. All functions return
  `{:ok, result}` or `{:error, reason}`.
  """

  alias Cyanea.Native

  # ===========================================================================
  # Sequence validation & operations
  # ===========================================================================

  @doc "Validate and normalize a DNA sequence. Returns `{:ok, binary}` or `{:error, reason}`."
  def validate_dna(data) when is_binary(data), do: nif_call(fn -> Native.validate_dna(data) end)

  @doc "Validate and normalize an RNA sequence."
  def validate_rna(data) when is_binary(data), do: nif_call(fn -> Native.validate_rna(data) end)

  @doc "Validate and normalize a protein sequence."
  def validate_protein(data) when is_binary(data), do: nif_call(fn -> Native.validate_protein(data) end)

  @doc "Reverse complement a DNA sequence."
  def dna_reverse_complement(data) when is_binary(data),
    do: nif_call(fn -> Native.dna_reverse_complement(data) end)

  @doc "Transcribe DNA to RNA."
  def dna_transcribe(data) when is_binary(data),
    do: nif_call(fn -> Native.dna_transcribe(data) end)

  @doc "Calculate GC content of a DNA sequence (fraction 0.0–1.0)."
  def dna_gc_content(data) when is_binary(data),
    do: nif_call(fn -> Native.dna_gc_content(data) end)

  @doc "Translate RNA to protein (NCBI Table 1)."
  def rna_translate(data) when is_binary(data),
    do: nif_call(fn -> Native.rna_translate(data) end)

  @doc "Extract k-mers from a DNA sequence."
  def sequence_kmers(data, k) when is_binary(data) and is_integer(k),
    do: nif_call(fn -> Native.sequence_kmers(data, k) end)

  @doc "Calculate molecular weight of a protein (Daltons)."
  def protein_molecular_weight(data) when is_binary(data),
    do: nif_call(fn -> Native.protein_molecular_weight(data) end)

  # ===========================================================================
  # File analysis
  # ===========================================================================

  @doc "Get FASTA file statistics (sequence count, bases, GC content)."
  def fasta_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.fasta_stats(path) end)

  @doc "Get FASTQ file statistics (includes quality metrics)."
  def fastq_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.fastq_stats(path) end)

  @doc "Parse all records from a FASTQ file."
  def parse_fastq(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_fastq(path) end)

  @doc "Get CSV file metadata (row count, columns)."
  def csv_info(path) when is_binary(path),
    do: nif_call(fn -> Native.csv_info(path) end)

  @doc "Preview first N rows of a CSV file as JSON."
  def csv_preview(path, limit \\ 100) when is_binary(path),
    do: nif_call(fn -> Native.csv_preview(path, limit) end)

  # ===========================================================================
  # Alignment
  # ===========================================================================

  @doc """
  Align two DNA sequences with default scoring (+2/-1/-5/-2).

  Mode is one of: "local", "global", "semiglobal".
  Returns `{:ok, %AlignmentResult{}}`.
  """
  def align_dna(query, target, mode \\ "local")
      when is_binary(query) and is_binary(target) and is_binary(mode),
      do: nif_call(fn -> Native.align_dna(query, target, mode) end)

  @doc """
  Align two DNA sequences with custom scoring parameters.
  """
  def align_dna_custom(query, target, mode, match_score, mismatch_score, gap_open, gap_extend),
    do: nif_call(fn -> Native.align_dna_custom(query, target, mode, match_score, mismatch_score, gap_open, gap_extend) end)

  @doc """
  Align two protein sequences.

  Matrix is one of: "blosum62", "blosum45", "blosum80", "pam250".
  """
  def align_protein(query, target, mode \\ "global", matrix \\ "blosum62"),
    do: nif_call(fn -> Native.align_protein(query, target, mode, matrix) end)

  @doc """
  Batch-align a list of `{query, target}` DNA pairs.
  Runs on the DirtyCpu scheduler for large workloads.
  """
  def align_batch_dna(pairs, mode \\ "local") when is_list(pairs),
    do: nif_call(fn -> Native.align_batch_dna(pairs, mode) end)

  # ===========================================================================
  # Statistics
  # ===========================================================================

  @doc "Compute descriptive statistics (15 fields) for a list of floats."
  def descriptive_stats(data) when is_list(data),
    do: nif_call(fn -> Native.descriptive_stats(data) end)

  @doc "Pearson product-moment correlation coefficient."
  def pearson_correlation(x, y) when is_list(x) and is_list(y),
    do: nif_call(fn -> Native.pearson_correlation(x, y) end)

  @doc "Spearman rank correlation coefficient."
  def spearman_correlation(x, y) when is_list(x) and is_list(y),
    do: nif_call(fn -> Native.spearman_correlation(x, y) end)

  @doc "One-sample t-test (test if population mean equals mu)."
  def t_test_one_sample(data, mu \\ 0.0) when is_list(data),
    do: nif_call(fn -> Native.t_test_one_sample(data, mu) end)

  @doc "Two-sample t-test. Set `equal_var: true` for Student's, `false` for Welch's."
  def t_test_two_sample(x, y, equal_var \\ false) when is_list(x) and is_list(y),
    do: nif_call(fn -> Native.t_test_two_sample(x, y, equal_var) end)

  @doc "Mann-Whitney U test (non-parametric, two independent samples)."
  def mann_whitney_u(x, y) when is_list(x) and is_list(y),
    do: nif_call(fn -> Native.mann_whitney_u(x, y) end)

  @doc "Bonferroni p-value correction."
  def p_adjust_bonferroni(p_values) when is_list(p_values),
    do: nif_call(fn -> Native.p_adjust_bonferroni(p_values) end)

  @doc "Benjamini-Hochberg FDR correction."
  def p_adjust_bh(p_values) when is_list(p_values),
    do: nif_call(fn -> Native.p_adjust_bh(p_values) end)

  # ===========================================================================
  # Omics
  # ===========================================================================

  @doc "Classify a genomic variant (SNV, insertion, deletion, etc.)."
  def classify_variant(chrom, position, ref_allele, alt_alleles),
    do: nif_call(fn -> Native.classify_variant(chrom, position, ref_allele, alt_alleles) end)

  @doc "Merge overlapping genomic intervals. Takes parallel arrays of chrom, start, end."
  def merge_genomic_intervals(chroms, starts, ends)
      when is_list(chroms) and is_list(starts) and is_list(ends),
      do: nif_call(fn -> Native.merge_genomic_intervals(chroms, starts, ends) end)

  @doc "Total bases covered on a chromosome after merging overlaps."
  def genomic_coverage(chroms, starts, ends, query_chrom),
    do: nif_call(fn -> Native.genomic_coverage(chroms, starts, ends, query_chrom) end)

  @doc "Compute expression matrix summary statistics."
  def expression_summary(data, feature_names, sample_names),
    do: nif_call(fn -> Native.expression_summary(data, feature_names, sample_names) end)

  @doc "Log2-transform a matrix: log2(x + pseudocount)."
  def log_transform_matrix(data, pseudocount \\ 1.0),
    do: nif_call(fn -> Native.log_transform_matrix(data, pseudocount) end)

  # ===========================================================================
  # Compression
  # ===========================================================================

  @doc "Compress data using zstd (level 1-22, default 3)."
  def zstd_compress(data, level \\ 3) when is_binary(data),
    do: nif_call(fn -> Native.zstd_compress(data, level) end)

  @doc "Decompress zstd data."
  def zstd_decompress(data) when is_binary(data),
    do: nif_call(fn -> Native.zstd_decompress(data) end)

  # ===========================================================================
  # Internal
  # ===========================================================================

  # Wraps a NIF call, normalizing error handling.
  # NIF functions return {:ok, result} | {:error, reason} or raise on :nif_not_loaded.
  defp nif_call(fun) do
    case fun.() do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  rescue
    ErlangError -> {:error, :nif_not_loaded}
  end
end

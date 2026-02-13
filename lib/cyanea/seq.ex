defmodule Cyanea.Seq do
  @moduledoc "Sequence validation, manipulation, pattern matching, and analysis."

  import Cyanea.NifHelper
  alias Cyanea.Native

  # ===========================================================================
  # Validation
  # ===========================================================================

  @type seq_type :: :dna | :rna | :protein

  @doc "Validate and normalize a sequence of the given type. Returns `{:ok, binary}` or `{:error, reason}`."
  @spec validate(binary(), seq_type()) :: {:ok, binary()} | {:error, term()}
  def validate(seq, :dna) when is_binary(seq), do: nif_call(fn -> Native.validate_dna(seq) end)
  def validate(seq, :rna) when is_binary(seq), do: nif_call(fn -> Native.validate_rna(seq) end)
  def validate(seq, :protein) when is_binary(seq), do: nif_call(fn -> Native.validate_protein(seq) end)

  @doc "Validate and normalize a sequence, raising on error."
  @spec validate!(binary(), seq_type()) :: binary()
  def validate!(seq, type) when is_binary(seq) do
    case validate(seq, type) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "validation failed: #{inspect(reason)}"
    end
  end

  # ===========================================================================
  # Operations
  # ===========================================================================

  @doc "Reverse complement a DNA sequence."
  @spec reverse_complement(binary()) :: {:ok, binary()} | {:error, term()}
  def reverse_complement(seq) when is_binary(seq),
    do: nif_call(fn -> Native.dna_reverse_complement(seq) end)

  @doc "Transcribe DNA to RNA (T -> U)."
  @spec transcribe(binary()) :: {:ok, binary()} | {:error, term()}
  def transcribe(seq) when is_binary(seq),
    do: nif_call(fn -> Native.dna_transcribe(seq) end)

  @doc "Translate RNA to protein (NCBI Table 1)."
  @spec translate(binary()) :: {:ok, binary()} | {:error, term()}
  def translate(seq) when is_binary(seq),
    do: nif_call(fn -> Native.rna_translate(seq) end)

  @doc "Calculate GC content of a DNA sequence (fraction 0.0-1.0)."
  @spec gc_content(binary()) :: {:ok, float()} | {:error, term()}
  def gc_content(seq) when is_binary(seq),
    do: nif_call(fn -> Native.dna_gc_content(seq) end)

  @doc "Extract k-mers from a DNA sequence."
  @spec kmers(binary(), pos_integer()) :: {:ok, [binary()]} | {:error, term()}
  def kmers(seq, k) when is_binary(seq) and is_integer(k),
    do: nif_call(fn -> Native.sequence_kmers(seq, k) end)

  @doc "Calculate molecular weight of a protein (Daltons)."
  @spec molecular_weight(binary()) :: {:ok, float()} | {:error, term()}
  def molecular_weight(seq) when is_binary(seq),
    do: nif_call(fn -> Native.protein_molecular_weight(seq) end)

  # ===========================================================================
  # Pattern matching
  # ===========================================================================

  @doc """
  Search for pattern matches in text.

  ## Options

    * `:algorithm` - `:horspool` (default, exact) or `:myers` (approximate)
    * `:max_distance` - maximum edit distance for Myers (default: 1)

  """
  @spec search(binary(), binary(), keyword()) :: {:ok, list()} | {:error, term()}
  def search(text, pattern, opts \\ [])

  def search(text, pattern, opts) when is_binary(text) and is_binary(pattern) do
    algorithm = Keyword.get(opts, :algorithm, :horspool)

    case algorithm do
      :horspool ->
        nif_call(fn -> Native.horspool_search(text, pattern) end)

      :myers ->
        max_dist = Keyword.get(opts, :max_distance, 1)
        nif_call(fn -> Native.myers_search(text, pattern, max_dist) end)
    end
  end

  # ===========================================================================
  # FM-Index
  # ===========================================================================

  @doc "Build an FM-index from text. Returns serialized index data."
  @spec build_index(binary()) :: {:ok, binary()} | {:error, term()}
  def build_index(text) when is_binary(text),
    do: nif_call(fn -> Native.fm_index_build(text) end)

  @doc "Count occurrences of pattern in FM-index."
  @spec count_occurrences(binary(), binary()) :: {:ok, non_neg_integer()} | {:error, term()}
  def count_occurrences(index_data, pattern) when is_binary(index_data) and is_binary(pattern),
    do: nif_call(fn -> Native.fm_index_count(index_data, pattern) end)

  # ===========================================================================
  # ORF finding
  # ===========================================================================

  @doc """
  Find open reading frames in both strands.

  ## Options

    * `:min_length` - minimum ORF length in nucleotides (default: 100)

  """
  @spec find_orfs(binary(), keyword()) :: {:ok, list()} | {:error, term()}
  def find_orfs(seq, opts \\ []) when is_binary(seq) do
    min_length = Keyword.get(opts, :min_length, 100)
    nif_call(fn -> Native.find_orfs(seq, min_length) end)
  end

  # ===========================================================================
  # MinHash
  # ===========================================================================

  @doc """
  Compute MinHash sketch of a sequence.

  ## Options

    * `:k` - k-mer size (default: 21)
    * `:sketch_size` - number of hash values (default: 1000)

  """
  @spec minhash(binary(), keyword()) :: {:ok, list()} | {:error, term()}
  def minhash(seq, opts \\ []) when is_binary(seq) do
    k = Keyword.get(opts, :k, 21)
    sketch_size = Keyword.get(opts, :sketch_size, 1000)
    nif_call(fn -> Native.minhash_sketch(seq, k, sketch_size) end)
  end

  @doc "Compute Jaccard similarity between two MinHash sketches."
  @spec minhash_jaccard(list(), list()) :: {:ok, float()} | {:error, term()}
  def minhash_jaccard(sketch_a, sketch_b) when is_list(sketch_a) and is_list(sketch_b),
    do: nif_call(fn -> Native.minhash_jaccard(sketch_a, sketch_b) end)

  # ===========================================================================
  # File I/O (sequence-specific)
  # ===========================================================================

  @doc "Get FASTA file statistics (sequence count, bases, GC content)."
  @spec fasta_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def fasta_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.fasta_stats(path) end)

  @doc "Get FASTQ file statistics (includes quality metrics)."
  @spec fastq_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def fastq_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.fastq_stats(path) end)

  @doc "Parse all records from a FASTQ file."
  @spec parse_fastq(binary()) :: {:ok, list()} | {:error, term()}
  def parse_fastq(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_fastq(path) end)
end

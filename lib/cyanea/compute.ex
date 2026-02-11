defmodule Cyanea.Compute do
  @moduledoc """
  High-level compute functions backed by Rust NIFs.

  Wraps `Cyanea.Native` with ergonomic APIs for sequence analysis,
  file formats, alignment, statistics, omics, ML, chemistry,
  structures, phylogenetics, and GPU detection. All functions return
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

  @doc "Get VCF file statistics (variant counts, chromosomes)."
  def vcf_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.vcf_stats(path) end)

  @doc "Get BED file statistics (record count, total bases, chromosomes)."
  def bed_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.bed_stats(path) end)

  @doc "Get GFF3 file statistics (gene/transcript/exon counts, chromosomes)."
  def gff3_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.gff3_stats(path) end)

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

  @doc """
  Progressive multiple sequence alignment.

  Mode is `"dna"` or `"protein"`. Returns `{:ok, %MsaResult{}}`.
  """
  def progressive_msa(sequences, mode \\ "dna") when is_list(sequences) and is_binary(mode),
    do: nif_call(fn -> Native.progressive_msa(sequences, mode) end)

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
  # ML — Clustering & Embeddings
  # ===========================================================================

  @doc """
  K-means clustering.

  `data` is a flat list of floats (row-major), `n_features` per row.
  Returns `{:ok, %KMeansResult{}}`.
  """
  def kmeans(data, n_features, k, max_iter \\ 100, seed \\ 42)
      when is_list(data) and is_integer(n_features) and is_integer(k)
      and is_integer(max_iter) and is_integer(seed),
      do: nif_call(fn -> Native.kmeans(data, n_features, k, max_iter, seed) end)

  @doc """
  DBSCAN density-based clustering.

  Metric is `"euclidean"`, `"manhattan"`, or `"cosine"`.
  Returns `{:ok, %DbscanResult{}}` where labels of `-1` indicate noise.
  """
  def dbscan(data, n_features, eps, min_samples, metric \\ "euclidean")
      when is_list(data) and is_integer(n_features)
      and is_number(eps) and is_integer(min_samples) and is_binary(metric),
      do: nif_call(fn -> Native.dbscan(data, n_features, eps, min_samples, metric) end)

  @doc """
  Principal component analysis.

  `data` is a flat list (row-major), `n_features` per row.
  Returns `{:ok, %PcaResult{}}`.
  """
  def pca(data, n_features, n_components)
      when is_list(data) and is_integer(n_features) and is_integer(n_components),
      do: nif_call(fn -> Native.pca(data, n_features, n_components) end)

  @doc """
  t-SNE dimensionality reduction.

  `data` is a flat list (row-major), `n_features` per row.
  Returns `{:ok, %TsneResult{}}`.
  """
  def tsne(data, n_features, n_components \\ 2, perplexity \\ 30.0, n_iter \\ 1000)
      when is_list(data) and is_integer(n_features)
      and is_integer(n_components) and is_number(perplexity) and is_integer(n_iter),
      do: nif_call(fn -> Native.tsne(data, n_features, n_components, perplexity, n_iter) end)

  @doc """
  Compute normalized k-mer frequency embedding for a sequence.

  Alphabet is `"dna"`, `"rna"`, or `"protein"`.
  Returns `{:ok, [float]}`.
  """
  def kmer_embedding(sequence, k, alphabet \\ "dna")
      when is_binary(sequence) and is_integer(k) and is_binary(alphabet),
      do: nif_call(fn -> Native.kmer_embedding(sequence, k, alphabet) end)

  @doc """
  Batch k-mer frequency embeddings for multiple sequences.

  Returns `{:ok, [[float]]}`.
  """
  def batch_embed(sequences, k, alphabet \\ "dna")
      when is_list(sequences) and is_integer(k) and is_binary(alphabet),
      do: nif_call(fn -> Native.batch_embed(sequences, k, alphabet) end)

  @doc """
  Compute pairwise distance matrix (condensed upper-triangle).

  Metric is `"euclidean"`, `"manhattan"`, or `"cosine"`.
  Returns `{:ok, [float]}` with `n*(n-1)/2` elements.
  """
  def pairwise_distances(data, n_features, metric \\ "euclidean")
      when is_list(data) and is_integer(n_features) and is_binary(metric),
      do: nif_call(fn -> Native.pairwise_distances(data, n_features, metric) end)

  # ===========================================================================
  # Chemistry — Small Molecules
  # ===========================================================================

  @doc """
  Parse a SMILES string and compute molecular properties.

  Returns `{:ok, %MolecularProperties{}}`.
  """
  def smiles_properties(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.smiles_properties(smiles) end)

  @doc """
  Compute Morgan fingerprint as a byte vector.

  Returns `{:ok, binary}` of `ceil(nbits/8)` bytes.
  """
  def smiles_fingerprint(smiles, radius \\ 2, nbits \\ 2048)
      when is_binary(smiles) and is_integer(radius) and is_integer(nbits),
      do: nif_call(fn -> Native.smiles_fingerprint(smiles, radius, nbits) end)

  @doc """
  Compute Tanimoto similarity between two SMILES via Morgan fingerprints.

  Returns `{:ok, float}` in the range `[0.0, 1.0]`.
  """
  def tanimoto(smiles_a, smiles_b, radius \\ 2, nbits \\ 2048)
      when is_binary(smiles_a) and is_binary(smiles_b)
      and is_integer(radius) and is_integer(nbits),
      do: nif_call(fn -> Native.tanimoto(smiles_a, smiles_b, radius, nbits) end)

  @doc "Check if target SMILES contains the pattern as a substructure."
  def smiles_substructure(target, pattern)
      when is_binary(target) and is_binary(pattern),
      do: nif_call(fn -> Native.smiles_substructure(target, pattern) end)

  # ===========================================================================
  # Structures — PDB
  # ===========================================================================

  @doc """
  Parse PDB text and return structure info.

  Returns `{:ok, %PdbInfo{}}`.
  """
  def pdb_info(pdb_text) when is_binary(pdb_text),
    do: nif_call(fn -> Native.pdb_info(pdb_text) end)

  @doc """
  Parse a PDB file from disk and return structure info.

  Returns `{:ok, %PdbInfo{}}`.
  """
  def pdb_file_info(path) when is_binary(path),
    do: nif_call(fn -> Native.pdb_file_info(path) end)

  @doc """
  Assign secondary structure (simplified DSSP) for a chain.

  `chain_id` is a single-character string (e.g. `"A"`).
  Returns `{:ok, %SecondaryStructure{}}`.
  """
  def pdb_secondary_structure(pdb_text, chain_id)
      when is_binary(pdb_text) and is_binary(chain_id),
      do: nif_call(fn -> Native.pdb_secondary_structure(pdb_text, chain_id) end)

  @doc """
  Compute RMSD between CA atoms of two chains from PDB text.

  Returns `{:ok, float}` (Angstroms).
  """
  def pdb_rmsd(pdb_a, pdb_b, chain_a, chain_b)
      when is_binary(pdb_a) and is_binary(pdb_b)
      and is_binary(chain_a) and is_binary(chain_b),
      do: nif_call(fn -> Native.pdb_rmsd(pdb_a, pdb_b, chain_a, chain_b) end)

  # ===========================================================================
  # Phylogenetics
  # ===========================================================================

  @doc """
  Parse a Newick string and return tree info.

  Returns `{:ok, %NewickInfo{}}`.
  """
  def newick_info(newick) when is_binary(newick),
    do: nif_call(fn -> Native.newick_info(newick) end)

  @doc """
  Compute Robinson-Foulds distance between two Newick trees.

  Returns `{:ok, non_neg_integer}`.
  """
  def newick_robinson_foulds(newick_a, newick_b)
      when is_binary(newick_a) and is_binary(newick_b),
      do: nif_call(fn -> Native.newick_robinson_foulds(newick_a, newick_b) end)

  @doc """
  Compute evolutionary distance between two aligned sequences.

  Model is `"p"` (p-distance), `"jc"` (Jukes-Cantor), or `"k2p"` (Kimura 2-parameter).
  Returns `{:ok, float}`.
  """
  def evolutionary_distance(seq_a, seq_b, model \\ "p")
      when is_binary(seq_a) and is_binary(seq_b) and is_binary(model),
      do: nif_call(fn -> Native.evolutionary_distance(seq_a, seq_b, model) end)

  @doc """
  Build a UPGMA tree from aligned sequences.

  Model is `"p"`, `"jc"`, or `"k2p"`. Returns `{:ok, newick_string}`.
  """
  def build_upgma(sequences, names, model \\ "p")
      when is_list(sequences) and is_list(names) and is_binary(model),
      do: nif_call(fn -> Native.build_upgma(sequences, names, model) end)

  @doc """
  Build a Neighbor-Joining tree from aligned sequences.

  Model is `"p"`, `"jc"`, or `"k2p"`. Returns `{:ok, newick_string}`.
  """
  def build_nj(sequences, names, model \\ "p")
      when is_list(sequences) and is_list(names) and is_binary(model),
      do: nif_call(fn -> Native.build_nj(sequences, names, model) end)

  # ===========================================================================
  # GPU
  # ===========================================================================

  @doc """
  Get GPU backend info.

  Returns `{:ok, %GpuInfo{}}` with `:available` (boolean) and `:backend` (`"cpu"`, `"cuda"`, or `"metal"`).
  """
  def gpu_info, do: nif_call(fn -> Native.gpu_info() end)

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

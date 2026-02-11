defmodule Cyanea.Native do
  @moduledoc """
  Rust NIF bindings for high-performance compute via Cyanea Labs.

  This module provides native functions backed by the Rust crates in `labs/`.
  Each section corresponds to a Cyanea Labs crate.

  ## Available (implemented)

  - **Hashing** — SHA256 checksums (cyanea-core)
  - **Compression** — zstd compress/decompress (cyanea-core)
  - **Sequences** — Validation, operations, k-mers, FASTA/FASTQ parsing (cyanea-seq)
  - **CSV** — Column info and preview (cyanea-io)
  - **Alignment** — Pairwise DNA/protein alignment, batch alignment (cyanea-align)
  - **Statistics** — Descriptive stats, correlation, hypothesis testing, p-value correction (cyanea-stats)
  - **Omics** — Variant classification, genomic intervals, expression matrices (cyanea-omics)

  - **File Formats** — VCF, BED, GFF3 stats (cyanea-io)
  - **MSA** — Progressive multiple sequence alignment (cyanea-align)
  - **ML** — Clustering, PCA, t-SNE, embeddings, distances (cyanea-ml)
  - **Chemistry** — SMILES properties, fingerprints, substructure (cyanea-chem)
  - **Structures** — PDB parsing, secondary structure, RMSD (cyanea-struct)
  - **Phylogenetics** — Newick parsing, tree distances, tree building (cyanea-phylo)
  - **GPU** — Backend detection (cyanea-gpu)
  """

  use Rustler,
    otp_app: :cyanea,
    crate: "cyanea_native",
    skip_compilation?: true

  # ===========================================================================
  # cyanea-core — Hashing & Compression
  # ===========================================================================

  @doc "Calculate SHA256 hash of binary data"
  def sha256(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Calculate SHA256 hash of a file"
  def sha256_file(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compress data using zstd (level 1-22, default 3)"
  def zstd_compress(_data, _level \\ 3), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Decompress zstd data"
  def zstd_decompress(_data), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-seq — Sequence I/O
  # ===========================================================================

  @doc "Get statistics from a FASTA/FASTQ file"
  def fasta_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  # --- Sequence validation --------------------------------------------------

  @doc "Validate and uppercase a DNA sequence (IUPAC alphabet)"
  def validate_dna(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Validate and uppercase an RNA sequence (IUPAC alphabet)"
  def validate_rna(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Validate and uppercase a protein sequence"
  def validate_protein(_data), do: :erlang.nif_error(:nif_not_loaded)

  # --- DNA operations -------------------------------------------------------

  @doc "Return the reverse complement of a DNA sequence"
  def dna_reverse_complement(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Transcribe DNA to RNA (T → U)"
  def dna_transcribe(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Calculate GC content of a DNA sequence (fraction 0.0–1.0)"
  def dna_gc_content(_data), do: :erlang.nif_error(:nif_not_loaded)

  # --- RNA operations -------------------------------------------------------

  @doc "Translate an RNA sequence to protein (NCBI Table 1)"
  def rna_translate(_data), do: :erlang.nif_error(:nif_not_loaded)

  # --- K-mers ---------------------------------------------------------------

  @doc "Extract k-mers from a DNA sequence as a list of binaries"
  def sequence_kmers(_data, _k), do: :erlang.nif_error(:nif_not_loaded)

  # --- FASTQ ----------------------------------------------------------------

  @doc "Parse a FASTQ file and return all records"
  def parse_fastq(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get streaming statistics from a FASTQ file"
  def fastq_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  # --- Protein --------------------------------------------------------------

  @doc "Calculate molecular weight of a protein sequence (Daltons)"
  def protein_molecular_weight(_data), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-io — File Format Parsing
  # ===========================================================================

  @doc "Get info about a CSV file (row count, columns)"
  def csv_info(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get preview of CSV file (first N rows as JSON)"
  def csv_preview(_path, _limit \\ 100), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get statistics from a VCF file (variant counts, chromosomes)"
  def vcf_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get statistics from a BED file (record count, total bases, chromosomes)"
  def bed_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get statistics from a GFF3 file (gene/transcript/exon counts, chromosomes)"
  def gff3_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-align — Sequence Alignment
  # ===========================================================================

  @doc "Align two DNA sequences with default scoring (+2/-1/-5/-2). Mode: \"local\", \"global\", or \"semiglobal\""
  def align_dna(_query, _target, _mode), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Align two DNA sequences with custom scoring parameters"
  def align_dna_custom(_query, _target, _mode, _match_score, _mismatch_score, _gap_open, _gap_extend),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Align two protein sequences. Matrix: \"blosum62\", \"blosum45\", \"blosum80\", or \"pam250\""
  def align_protein(_query, _target, _mode, _matrix), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Batch-align a list of {query, target} DNA pairs (runs on DirtyCpu scheduler)"
  def align_batch_dna(_pairs, _mode), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Progressive multiple sequence alignment. Mode: \"dna\" or \"protein\""
  def progressive_msa(_sequences, _mode), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-stats — Statistical Methods
  # ===========================================================================

  @doc "Compute descriptive statistics (15 fields) for a list of floats"
  def descriptive_stats(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Pearson product-moment correlation coefficient"
  def pearson_correlation(_x, _y), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Spearman rank correlation coefficient"
  def spearman_correlation(_x, _y), do: :erlang.nif_error(:nif_not_loaded)

  @doc "One-sample t-test (test if population mean equals mu)"
  def t_test_one_sample(_data, _mu), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Two-sample t-test. Set equal_var to true for Student's, false for Welch's"
  def t_test_two_sample(_x, _y, _equal_var), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Mann-Whitney U test (non-parametric, two independent samples)"
  def mann_whitney_u(_x, _y), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Bonferroni p-value correction (controls family-wise error rate)"
  def p_adjust_bonferroni(_p_values), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Benjamini-Hochberg p-value correction (controls false discovery rate)"
  def p_adjust_bh(_p_values), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-omics — Omics Data Structures
  # ===========================================================================

  @doc "Classify a genomic variant (SNV, insertion, deletion, etc.)"
  def classify_variant(_chrom, _position, _ref_allele, _alt_alleles),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Merge overlapping genomic intervals (parallel arrays of chrom, start, end)"
  def merge_genomic_intervals(_chroms, _starts, _ends),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Total bases covered on a chromosome (after merging overlaps)"
  def genomic_coverage(_chroms, _starts, _ends, _query_chrom),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute summary statistics for an expression matrix (2D list of floats)"
  def expression_summary(_data, _feature_names, _sample_names),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Log2-transform a matrix: log2(x + pseudocount) for all values"
  def log_transform_matrix(_data, _pseudocount), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-ml — ML Primitives
  # ===========================================================================

  @doc "K-means clustering. Data is a flat list (row-major), n_features per row"
  def kmeans(_data, _n_features, _k, _max_iter, _seed),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "DBSCAN clustering. Metric: \"euclidean\", \"manhattan\", or \"cosine\""
  def dbscan(_data, _n_features, _eps, _min_samples, _metric),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Principal component analysis on flat row-major data"
  def pca(_data, _n_features, _n_components), do: :erlang.nif_error(:nif_not_loaded)

  @doc "t-SNE dimensionality reduction on flat row-major data"
  def tsne(_data, _n_features, _n_components, _perplexity, _n_iter),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute normalized k-mer frequency embedding for a sequence"
  def kmer_embedding(_sequence, _k, _alphabet), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Batch k-mer frequency embeddings for multiple sequences (DirtyCpu)"
  def batch_embed(_sequences, _k, _alphabet), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute pairwise distance matrix (condensed upper-triangle)"
  def pairwise_distances(_data, _n_features, _metric),
    do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-chem — Chemistry / Small Molecules
  # ===========================================================================

  @doc "Parse SMILES and compute molecular properties"
  def smiles_properties(_smiles), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Morgan fingerprint as byte vector. Returns binary of ceil(nbits/8) bytes"
  def smiles_fingerprint(_smiles, _radius, _nbits),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Tanimoto similarity between two SMILES via Morgan fingerprints"
  def tanimoto(_smiles_a, _smiles_b, _radius, _nbits),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Check if target SMILES contains the pattern SMILES as a substructure"
  def smiles_substructure(_target, _pattern), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-struct — 3D Structures
  # ===========================================================================

  @doc "Parse PDB text and return structure info (chains, residues, atoms)"
  def pdb_info(_pdb_text), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse a PDB file from disk and return structure info (DirtyCpu)"
  def pdb_file_info(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Assign secondary structure (simplified DSSP) for a chain"
  def pdb_secondary_structure(_pdb_text, _chain_id),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute RMSD between CA atoms of two chains from PDB text"
  def pdb_rmsd(_pdb_a, _pdb_b, _chain_a, _chain_b),
    do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-phylo — Phylogenetics
  # ===========================================================================

  @doc "Parse a Newick string and return tree info (leaf count, names, canonical Newick)"
  def newick_info(_newick), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Robinson-Foulds distance between two Newick trees"
  def newick_robinson_foulds(_newick_a, _newick_b),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute evolutionary distance between two sequences. Model: \"p\", \"jc\", or \"k2p\""
  def evolutionary_distance(_seq_a, _seq_b, _model),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Build UPGMA tree from sequences. Returns Newick string"
  def build_upgma(_sequences, _names, _model), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Build Neighbor-Joining tree from sequences. Returns Newick string"
  def build_nj(_sequences, _names, _model), do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-gpu — GPU Compute
  # ===========================================================================

  @doc "Get GPU backend info (available backends, current selection)"
  def gpu_info(), do: :erlang.nif_error(:nif_not_loaded)
end

# ===========================================================================
# Bridge structs — match Rust NifStruct modules
# ===========================================================================

# --- cyanea-seq ---

defmodule Cyanea.Native.FastaStats do
  @moduledoc "FASTA file statistics (cyanea-seq)"
  defstruct [:sequence_count, :total_bases, :gc_content, :avg_length]
end

defmodule Cyanea.Native.CsvInfo do
  @moduledoc "CSV file metadata (cyanea-io)"
  defstruct [:row_count, :column_count, :columns, :has_headers]
end

defmodule Cyanea.Native.FastqRecord do
  @moduledoc "FASTQ record (cyanea-seq)"
  defstruct [:name, :description, :sequence, :quality]
end

defmodule Cyanea.Native.FastqStats do
  @moduledoc "FASTQ file statistics (cyanea-seq)"
  defstruct [:sequence_count, :total_bases, :gc_content, :avg_length,
             :mean_quality, :q20_fraction, :q30_fraction]
end

# --- cyanea-align ---

defmodule Cyanea.Native.AlignmentResult do
  @moduledoc "Pairwise alignment result (cyanea-align)"
  defstruct [:score, :aligned_query, :aligned_target,
             :query_start, :query_end, :target_start, :target_end,
             :cigar, :identity, :num_matches, :num_mismatches,
             :num_gaps, :alignment_length]
end

# --- cyanea-stats ---

defmodule Cyanea.Native.DescriptiveStats do
  @moduledoc "Descriptive statistics result (cyanea-stats)"
  defstruct [:count, :mean, :median, :variance, :sample_variance,
             :std_dev, :sample_std_dev, :min, :max, :range,
             :q1, :q3, :iqr, :skewness, :kurtosis]
end

defmodule Cyanea.Native.TestResult do
  @moduledoc "Hypothesis test result (cyanea-stats)"
  defstruct [:statistic, :p_value, :degrees_of_freedom, :method]
end

# --- cyanea-omics ---

defmodule Cyanea.Native.VariantClassification do
  @moduledoc "Variant classification result (cyanea-omics)"
  defstruct [:chrom, :position, :variant_type,
             :is_snv, :is_indel, :is_transition, :is_transversion]
end

defmodule Cyanea.Native.GenomicInterval do
  @moduledoc "Genomic interval (cyanea-omics)"
  defstruct [:chrom, :start, :end, :strand]
end

defmodule Cyanea.Native.ExpressionSummary do
  @moduledoc "Expression matrix summary (cyanea-omics)"
  defstruct [:n_features, :n_samples, :feature_names, :sample_names,
             :feature_means, :sample_means]
end

# --- cyanea-io (format stats) ---

defmodule Cyanea.Native.VcfStats do
  @moduledoc "VCF file statistics (cyanea-io)"
  defstruct [:variant_count, :snv_count, :indel_count, :pass_count, :chromosomes]
end

defmodule Cyanea.Native.BedStats do
  @moduledoc "BED file statistics (cyanea-io)"
  defstruct [:record_count, :total_bases, :chromosomes]
end

defmodule Cyanea.Native.GffStats do
  @moduledoc "GFF3 file statistics (cyanea-io)"
  defstruct [:gene_count, :transcript_count, :exon_count,
             :protein_coding_count, :chromosomes]
end

# --- cyanea-align (MSA) ---

defmodule Cyanea.Native.MsaResult do
  @moduledoc "Multiple sequence alignment result (cyanea-align)"
  defstruct [:aligned, :n_sequences, :n_columns, :conservation]
end

# --- cyanea-ml ---

defmodule Cyanea.Native.KMeansResult do
  @moduledoc "K-means clustering result (cyanea-ml)"
  defstruct [:labels, :centroids, :n_features, :inertia, :n_iter]
end

defmodule Cyanea.Native.DbscanResult do
  @moduledoc "DBSCAN clustering result (cyanea-ml)"
  defstruct [:labels, :n_clusters]
end

defmodule Cyanea.Native.PcaResult do
  @moduledoc "PCA result (cyanea-ml)"
  defstruct [:transformed, :explained_variance, :explained_variance_ratio,
             :components, :n_components, :n_features]
end

defmodule Cyanea.Native.TsneResult do
  @moduledoc "t-SNE result (cyanea-ml)"
  defstruct [:embedding, :n_samples, :n_components, :kl_divergence]
end

# --- cyanea-chem ---

defmodule Cyanea.Native.MolecularProperties do
  @moduledoc "Molecular properties from SMILES (cyanea-chem)"
  defstruct [:formula, :weight, :exact_mass, :hbd, :hba,
             :rotatable_bonds, :ring_count, :aromatic_ring_count,
             :atom_count, :bond_count]
end

# --- cyanea-struct ---

defmodule Cyanea.Native.PdbInfo do
  @moduledoc "PDB structure info (cyanea-struct)"
  defstruct [:id, :chain_count, :residue_count, :atom_count, :chains]
end

defmodule Cyanea.Native.SecondaryStructure do
  @moduledoc "Secondary structure assignment (cyanea-struct)"
  defstruct [:assignments, :helix_fraction, :sheet_fraction, :coil_fraction]
end

# --- cyanea-phylo ---

defmodule Cyanea.Native.NewickInfo do
  @moduledoc "Newick tree info (cyanea-phylo)"
  defstruct [:leaf_count, :leaf_names, :newick]
end

# --- cyanea-gpu ---

defmodule Cyanea.Native.GpuInfo do
  @moduledoc "GPU backend info (cyanea-gpu)"
  defstruct [:available, :backend]
end

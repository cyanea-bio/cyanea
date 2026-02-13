defmodule Cyanea.Native do
  @moduledoc """
  Rust NIF bindings for high-performance compute via Cyanea Labs.

  This module provides native functions backed by the Rust crates in `labs/`.
  Each section corresponds to a Cyanea Labs crate.

  ## Available (implemented)

  - **Hashing** — SHA256 checksums (cyanea-core)
  - **Compression** — zstd/gzip compress/decompress (cyanea-core)
  - **Sequences** — Validation, operations, k-mers, FASTA/FASTQ parsing, pattern matching, ORFs, MinHash (cyanea-seq)
  - **File Formats** — CSV, VCF, BED, GFF3, SAM, BAM parsing + stats (cyanea-io)
  - **Alignment** — Pairwise DNA/protein, batch, banded, MSA, POA consensus (cyanea-align)
  - **Statistics** — Descriptive, correlation, hypothesis testing, p-value correction, distributions, effect sizes, Bayesian (cyanea-stats)
  - **Omics** — Variant classification, genomic intervals, expression matrices (cyanea-omics)
  - **ML** — Clustering (k-means, DBSCAN, hierarchical), PCA, t-SNE, UMAP, KNN, linear regression, random forest, HMM, embeddings, distances (cyanea-ml)
  - **Chemistry** — SMILES properties, fingerprints (Morgan, MACCS), substructure, canonical SMILES, SDF parsing (cyanea-chem)
  - **Structures** — PDB/mmCIF parsing, secondary structure, RMSD, Kabsch, contact maps, Ramachandran, B-factor (cyanea-struct)
  - **Phylogenetics** — Newick/NEXUS I/O, tree distances, tree building, bootstrap, ancestral reconstruction (cyanea-phylo)
  - **GPU** — Backend detection, pairwise distances, matrix multiply, reduction, z-score (cyanea-gpu)
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

  @doc "Compress data using gzip (level 0-9)"
  def gzip_compress(_data, _level), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Decompress gzip data"
  def gzip_decompress(_data), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- Pattern matching (new) -----------------------------------------------

  @doc "Search for exact pattern matches using Horspool algorithm"
  def horspool_search(_text, _pattern), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Approximate pattern matching using Myers bit-parallel algorithm"
  def myers_search(_text, _pattern, _max_dist), do: :erlang.nif_error(:nif_not_loaded)

  # --- FM-Index (new) -------------------------------------------------------

  @doc "Build an FM-index from text. Returns serialized index as binary"
  def fm_index_build(_text), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Count occurrences of pattern in FM-index"
  def fm_index_count(_index_data, _pattern), do: :erlang.nif_error(:nif_not_loaded)

  # --- ORF finding (new) ----------------------------------------------------

  @doc "Find open reading frames in both strands of a DNA sequence"
  def find_orfs(_seq, _min_length), do: :erlang.nif_error(:nif_not_loaded)

  # --- MinHash (new) --------------------------------------------------------

  @doc "Compute MinHash sketch of a sequence"
  def minhash_sketch(_seq, _k, _sketch_size), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- New file format parsers -----------------------------------------------

  @doc "Parse a VCF file and return all variant records"
  def parse_vcf(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse a BED file and return all records"
  def parse_bed(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse a GFF3 file and return all gene records"
  def parse_gff3(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get statistics from a SAM file"
  def sam_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get statistics from a BAM file"
  def bam_stats(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse a SAM file and return all alignment records"
  def parse_sam(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse a BAM file and return all alignment records"
  def parse_bam(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse a BED file and return genomic intervals"
  def parse_bed_intervals(_path), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- New alignment functions -----------------------------------------------

  @doc "Banded DNA alignment. Restricts DP to diagonal band of 2*bandwidth+1"
  def banded_align_dna(_query, _target, _mode, _bandwidth), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Banded alignment score only (no traceback, less memory)"
  def banded_score_only(_query, _target, _mode, _bandwidth), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute consensus from multiple sequences using Partial Order Alignment"
  def poa_consensus(_sequences), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- New stats functions ---------------------------------------------------

  @doc "Cohen's d effect size between two groups"
  def cohens_d(_group1, _group2), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Odds ratio from a 2x2 contingency table (a, b, c, d)"
  def odds_ratio(_a, _b, _c, _d), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Normal distribution CDF at x with parameters mu and sigma"
  def normal_cdf(_x, _mu, _sigma), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Normal distribution PDF at x with parameters mu and sigma"
  def normal_pdf(_x, _mu, _sigma), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Chi-squared distribution CDF at x with df degrees of freedom"
  def chi_squared_cdf(_x, _df), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Bayesian beta-binomial conjugate update. Returns {posterior_alpha, posterior_beta}"
  def bayesian_beta_update(_alpha, _beta, _successes, _trials),
    do: :erlang.nif_error(:nif_not_loaded)

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

  @doc "UMAP dimensionality reduction. Metric: \"euclidean\", \"manhattan\", or \"cosine\""
  def umap(_data, _n_features, _n_components, _n_neighbors, _min_dist, _n_epochs, _metric, _seed),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute normalized k-mer frequency embedding for a sequence"
  def kmer_embedding(_sequence, _k, _alphabet), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Batch k-mer frequency embeddings for multiple sequences (DirtyCpu)"
  def batch_embed(_sequences, _k, _alphabet), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute pairwise distance matrix (condensed upper-triangle)"
  def pairwise_distances(_data, _n_features, _metric),
    do: :erlang.nif_error(:nif_not_loaded)

  # --- New ML functions ------------------------------------------------------

  @doc "Hierarchical (agglomerative) clustering. Linkage: \"single\", \"complete\", or \"average\""
  def hierarchical_cluster(_data, _n_features, _n_clusters, _linkage, _metric),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "K-nearest neighbor classification"
  def knn_classify(_data, _n_features, _k, _metric, _labels, _query),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Fit a linear regression model. Returns weights, bias, r_squared"
  def linear_regression_fit(_data, _n_features, _targets),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Predict using linear regression weights and bias"
  def linear_regression_predict(_weights, _bias, _queries, _n_features),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Fit a random forest classifier. Returns serialized model as binary"
  def random_forest_fit(_data, _n_features, _labels, _n_trees, _max_depth, _seed),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Predict class label using a serialized random forest model"
  def random_forest_predict(_model_data, _sample, _n_features),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "HMM Viterbi decoding. Returns {most_likely_path, log_probability}"
  def hmm_viterbi(_n_states, _n_symbols, _initial, _transition, _emission, _observations),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "HMM forward algorithm. Returns log-probability of observation sequence"
  def hmm_forward(_n_states, _n_symbols, _initial, _transition, _emission, _observations),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Min-max normalize data to [0, 1]"
  def normalize_min_max(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Z-score normalize data (zero mean, unit variance)"
  def normalize_z_score(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute silhouette score for clustering quality"
  def silhouette_score(_data, _n_features, _labels, _metric),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Jaccard similarity between two MinHash sketches"
  def minhash_jaccard(_sketch_a, _sketch_b), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- New chemistry functions -----------------------------------------------

  @doc "Generate canonical SMILES from input SMILES"
  def canonical_smiles(_smiles), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse an SDF file and return molecule summaries"
  def parse_sdf_file(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute MACCS fingerprint as byte vector"
  def maccs_fingerprint(_smiles), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- New struct functions --------------------------------------------------

  @doc "Parse mmCIF text and return structure info"
  def mmcif_info(_mmcif_text), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute contact map for a chain. Returns contacts within cutoff distance"
  def pdb_contact_map(_pdb_text, _chain_id, _cutoff),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Kabsch superposition of CA atoms. Returns RMSD, rotation matrix, translation"
  def pdb_kabsch(_pdb_a, _pdb_b, _chain_a, _chain_b),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute Ramachandran phi/psi angles for all residues"
  def pdb_ramachandran(_pdb_text), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Analyze B-factor distribution across the structure"
  def pdb_bfactor_analysis(_pdb_text), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Parse an mmCIF file from disk and return structure info (DirtyCpu)"
  def mmcif_file_info(_path), do: :erlang.nif_error(:nif_not_loaded)

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

  # --- New phylo functions ---------------------------------------------------

  @doc "Parse NEXUS format text and return taxa and tree data"
  def nexus_parse(_nexus_text), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Write taxa and trees to NEXUS format string"
  def nexus_write(_taxa, _trees_newick), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute normalized Robinson-Foulds distance (0.0-1.0)"
  def robinson_foulds_normalized(_newick_a, _newick_b),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Compute bootstrap support values for tree branches"
  def bootstrap_support(_sequences, _tree_newick, _n_replicates, _model),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Ancestral state reconstruction using Fitch parsimony"
  def ancestral_reconstruction(_tree_newick, _leaf_states),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Branch score distance between two trees"
  def branch_score_distance(_newick_a, _newick_b),
    do: :erlang.nif_error(:nif_not_loaded)

  # ===========================================================================
  # cyanea-gpu — GPU Compute
  # ===========================================================================

  @doc "Get GPU backend info (available backends, current selection)"
  def gpu_info(), do: :erlang.nif_error(:nif_not_loaded)

  # --- New GPU functions -----------------------------------------------------

  @doc "Compute pairwise distance matrix on GPU"
  def gpu_pairwise_distances(_data, _n, _dim, _metric),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Matrix multiplication on GPU (a: m×k, b: k×n → result: m×n)"
  def gpu_matrix_multiply(_a, _b, _m, _k, _n),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc "Sum reduction on GPU"
  def gpu_reduce_sum(_data), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Batch z-score normalization on GPU (per-row)"
  def gpu_batch_z_score(_data, _n_rows, _n_cols),
    do: :erlang.nif_error(:nif_not_loaded)
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

defmodule Cyanea.Native.OrfResult do
  @moduledoc "Open reading frame result (cyanea-seq)"
  defstruct [:start, :end, :frame, :strand, :sequence]
end

# --- cyanea-align ---

defmodule Cyanea.Native.AlignmentResult do
  @moduledoc "Pairwise alignment result (cyanea-align)"
  defstruct [:score, :aligned_query, :aligned_target,
             :query_start, :query_end, :target_start, :target_end,
             :cigar, :identity, :num_matches, :num_mismatches,
             :num_gaps, :alignment_length]
end

defmodule Cyanea.Native.MsaResult do
  @moduledoc "Multiple sequence alignment result (cyanea-align)"
  defstruct [:aligned, :n_sequences, :n_columns, :conservation]
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

# --- cyanea-io (record types — new) ---

defmodule Cyanea.Native.VcfRecord do
  @moduledoc "VCF variant record (cyanea-io)"
  defstruct [:chrom, :position, :ref_allele, :alt_alleles, :quality, :filter]
end

defmodule Cyanea.Native.BedRecord do
  @moduledoc "BED record (cyanea-io)"
  defstruct [:chrom, :start, :end, :name, :score, :strand]
end

defmodule Cyanea.Native.GffGene do
  @moduledoc "GFF3 gene record (cyanea-io)"
  defstruct [:id, :symbol, :chrom, :start, :end, :strand, :gene_type, :transcript_count]
end

defmodule Cyanea.Native.SamRecord do
  @moduledoc "SAM/BAM alignment record (cyanea-io)"
  defstruct [:qname, :flag, :rname, :pos, :mapq, :cigar, :sequence, :quality]
end

defmodule Cyanea.Native.SamStats do
  @moduledoc "SAM/BAM alignment statistics (cyanea-io)"
  defstruct [:total_reads, :mapped, :unmapped, :avg_mapq, :avg_length]
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

defmodule Cyanea.Native.UmapResult do
  @moduledoc "UMAP result (cyanea-ml)"
  defstruct [:embedding, :n_samples, :n_components, :n_epochs]
end

defmodule Cyanea.Native.HierarchicalResult do
  @moduledoc "Hierarchical clustering result (cyanea-ml)"
  defstruct [:labels, :merge_distances]
end

defmodule Cyanea.Native.LinearRegressionResult do
  @moduledoc "Linear regression result (cyanea-ml)"
  defstruct [:weights, :bias, :r_squared]
end

# --- cyanea-chem ---

defmodule Cyanea.Native.MolecularProperties do
  @moduledoc "Molecular properties from SMILES (cyanea-chem)"
  defstruct [:formula, :weight, :exact_mass, :hbd, :hba,
             :rotatable_bonds, :ring_count, :aromatic_ring_count,
             :atom_count, :bond_count]
end

defmodule Cyanea.Native.SdfMolecule do
  @moduledoc "SDF molecule summary (cyanea-chem)"
  defstruct [:name, :atom_count, :bond_count, :formula, :weight]
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

defmodule Cyanea.Native.ContactMapResult do
  @moduledoc "Contact map result (cyanea-struct)"
  defstruct [:contacts, :n_residues, :contact_density]
end

defmodule Cyanea.Native.SuperpositionResult do
  @moduledoc "Kabsch superposition result (cyanea-struct)"
  defstruct [:rmsd, :rotation, :translation]
end

defmodule Cyanea.Native.RamachandranEntry do
  @moduledoc "Ramachandran angle entry (cyanea-struct)"
  defstruct [:residue_num, :residue_name, :phi, :psi, :region]
end

defmodule Cyanea.Native.BfactorResult do
  @moduledoc "B-factor analysis result (cyanea-struct)"
  defstruct [:mean, :std_dev, :min, :max, :per_chain]
end

# --- cyanea-phylo ---

defmodule Cyanea.Native.NewickInfo do
  @moduledoc "Newick tree info (cyanea-phylo)"
  defstruct [:leaf_count, :leaf_names, :newick]
end

defmodule Cyanea.Native.NexusFile do
  @moduledoc "NEXUS file data (cyanea-phylo)"
  defstruct [:taxa, :tree_names, :tree_newicks]
end

# --- cyanea-gpu ---

defmodule Cyanea.Native.GpuInfo do
  @moduledoc "GPU backend info (cyanea-gpu)"
  defstruct [:available, :backend]
end

defmodule Cyanea.Compute do
  @moduledoc """
  High-level compute functions backed by Rust NIFs.

  > **Deprecated:** This flat module is retained for backward compatibility.
  > Prefer the domain-specific context modules instead:
  >
  > | Module | Domain |
  > |--------|--------|
  > | `Cyanea.Seq` | Sequence validation, manipulation, pattern matching |
  > | `Cyanea.Align` | Pairwise and multiple sequence alignment |
  > | `Cyanea.Stats` | Descriptive statistics, hypothesis testing |
  > | `Cyanea.ML` | Clustering, reduction, classification |
  > | `Cyanea.Chem` | SMILES, fingerprints, similarity |
  > | `Cyanea.StructBio` | PDB/mmCIF structure analysis |
  > | `Cyanea.Phylo` | Phylogenetic trees and distances |
  > | `Cyanea.Formats` | CSV, VCF, BED, GFF3, SAM, BAM parsing |
  > | `Cyanea.Omics` | Variants, intervals, expression matrices |
  > | `Cyanea.Core` | SHA256, zstd, gzip |
  > | `Cyanea.GPU` | GPU-accelerated compute |
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

  # --- Pattern matching (new) -----------------------------------------------

  @doc "Search for exact pattern matches using Horspool algorithm. Returns list of positions."
  def horspool_search(text, pattern) when is_binary(text) and is_binary(pattern),
    do: nif_call(fn -> Native.horspool_search(text, pattern) end)

  @doc "Approximate pattern matching using Myers bit-parallel algorithm. Returns `{position, distance}` pairs."
  def myers_search(text, pattern, max_dist)
      when is_binary(text) and is_binary(pattern) and is_integer(max_dist),
      do: nif_call(fn -> Native.myers_search(text, pattern, max_dist) end)

  # --- FM-Index (new) -------------------------------------------------------

  @doc "Build an FM-index from text. Returns serialized index data."
  def fm_index_build(text) when is_binary(text),
    do: nif_call(fn -> Native.fm_index_build(text) end)

  @doc "Count occurrences of pattern in FM-index."
  def fm_index_count(index_data, pattern) when is_binary(index_data) and is_binary(pattern),
    do: nif_call(fn -> Native.fm_index_count(index_data, pattern) end)

  # --- ORF finding (new) ----------------------------------------------------

  @doc "Find open reading frames in both strands. Returns list of `%OrfResult{}`."
  def find_orfs(seq, min_length \\ 100) when is_binary(seq) and is_integer(min_length),
    do: nif_call(fn -> Native.find_orfs(seq, min_length) end)

  # --- MinHash (new) --------------------------------------------------------

  @doc "Compute MinHash sketch of a sequence. Returns list of hash values."
  def minhash_sketch(seq, k, sketch_size)
      when is_binary(seq) and is_integer(k) and is_integer(sketch_size),
      do: nif_call(fn -> Native.minhash_sketch(seq, k, sketch_size) end)

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

  # --- New file format parsers (new) ----------------------------------------

  @doc "Parse a VCF file and return all variant records."
  def parse_vcf(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_vcf(path) end)

  @doc "Parse a BED file and return all records."
  def parse_bed(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_bed(path) end)

  @doc "Parse a GFF3 file and return all gene records."
  def parse_gff3(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_gff3(path) end)

  @doc "Get statistics from a SAM file."
  def sam_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.sam_stats(path) end)

  @doc "Get statistics from a BAM file."
  def bam_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.bam_stats(path) end)

  @doc "Parse a SAM file and return all alignment records."
  def parse_sam(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_sam(path) end)

  @doc "Parse a BAM file and return all alignment records."
  def parse_bam(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_bam(path) end)

  @doc "Parse a BED file and return genomic intervals."
  def parse_bed_intervals(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_bed_intervals(path) end)

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

  @doc "Align two DNA sequences with custom scoring parameters."
  def align_dna_custom(query, target, mode, match_score, mismatch_score, gap_open, gap_extend),
    do: nif_call(fn -> Native.align_dna_custom(query, target, mode, match_score, mismatch_score, gap_open, gap_extend) end)

  @doc """
  Align two protein sequences.

  Matrix is one of: "blosum62", "blosum45", "blosum80", "pam250".
  """
  def align_protein(query, target, mode \\ "global", matrix \\ "blosum62"),
    do: nif_call(fn -> Native.align_protein(query, target, mode, matrix) end)

  @doc "Batch-align a list of `{query, target}` DNA pairs (DirtyCpu scheduler)."
  def align_batch_dna(pairs, mode \\ "local") when is_list(pairs),
    do: nif_call(fn -> Native.align_batch_dna(pairs, mode) end)

  @doc """
  Progressive multiple sequence alignment.

  Mode is `"dna"` or `"protein"`. Returns `{:ok, %MsaResult{}}`.
  """
  def progressive_msa(sequences, mode \\ "dna") when is_list(sequences) and is_binary(mode),
    do: nif_call(fn -> Native.progressive_msa(sequences, mode) end)

  # --- Banded & POA (new) ---------------------------------------------------

  @doc "Banded DNA alignment. Restricts DP to diagonal band of `2*bandwidth+1`."
  def banded_align_dna(query, target, mode \\ "global", bandwidth \\ 50)
      when is_binary(query) and is_binary(target) and is_binary(mode) and is_integer(bandwidth),
      do: nif_call(fn -> Native.banded_align_dna(query, target, mode, bandwidth) end)

  @doc "Banded alignment score only (no traceback, less memory)."
  def banded_score_only(query, target, mode \\ "global", bandwidth \\ 50)
      when is_binary(query) and is_binary(target) and is_binary(mode) and is_integer(bandwidth),
      do: nif_call(fn -> Native.banded_score_only(query, target, mode, bandwidth) end)

  @doc "Compute consensus from multiple sequences using Partial Order Alignment."
  def poa_consensus(sequences) when is_list(sequences),
    do: nif_call(fn -> Native.poa_consensus(sequences) end)

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

  # --- Effect sizes & distributions (new) -----------------------------------

  @doc "Cohen's d effect size between two groups."
  def cohens_d(group1, group2) when is_list(group1) and is_list(group2),
    do: nif_call(fn -> Native.cohens_d(group1, group2) end)

  @doc "Odds ratio from a 2x2 contingency table (a, b, c, d)."
  def odds_ratio(a, b, c, d)
      when is_integer(a) and is_integer(b) and is_integer(c) and is_integer(d),
      do: nif_call(fn -> Native.odds_ratio(a, b, c, d) end)

  @doc "Normal distribution CDF at x with parameters mu and sigma."
  def normal_cdf(x, mu \\ 0.0, sigma \\ 1.0)
      when is_number(x) and is_number(mu) and is_number(sigma),
      do: nif_call(fn -> Native.normal_cdf(x, mu, sigma) end)

  @doc "Normal distribution PDF at x with parameters mu and sigma."
  def normal_pdf(x, mu \\ 0.0, sigma \\ 1.0)
      when is_number(x) and is_number(mu) and is_number(sigma),
      do: nif_call(fn -> Native.normal_pdf(x, mu, sigma) end)

  @doc "Chi-squared distribution CDF at x with df degrees of freedom."
  def chi_squared_cdf(x, df) when is_number(x) and is_number(df),
    do: nif_call(fn -> Native.chi_squared_cdf(x, df) end)

  @doc "Bayesian beta-binomial conjugate update. Returns `{:ok, {posterior_alpha, posterior_beta}}`."
  def bayesian_beta_update(alpha, beta, successes, trials)
      when is_number(alpha) and is_number(beta)
      and is_integer(successes) and is_integer(trials),
      do: nif_call(fn -> Native.bayesian_beta_update(alpha, beta, successes, trials) end)

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
  # Compression & Hashing
  # ===========================================================================

  @doc "SHA256 hash of binary data."
  def sha256(data) when is_binary(data),
    do: nif_call(fn -> Native.sha256(data) end)

  @doc "SHA256 hash of a file."
  def sha256_file(path) when is_binary(path),
    do: nif_call(fn -> Native.sha256_file(path) end)

  @doc "Compress data using zstd (level 1-22, default 3)."
  def zstd_compress(data, level \\ 3) when is_binary(data),
    do: nif_call(fn -> Native.zstd_compress(data, level) end)

  @doc "Decompress zstd data."
  def zstd_decompress(data) when is_binary(data),
    do: nif_call(fn -> Native.zstd_decompress(data) end)

  @doc "Compress data using gzip (level 0-9)."
  def gzip_compress(data, level \\ 6) when is_binary(data) and is_integer(level),
    do: nif_call(fn -> Native.gzip_compress(data, level) end)

  @doc "Decompress gzip data."
  def gzip_decompress(data) when is_binary(data),
    do: nif_call(fn -> Native.gzip_decompress(data) end)

  # ===========================================================================
  # ML — Clustering, Dimensionality Reduction & Embeddings
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

  @doc "Hierarchical (agglomerative) clustering. Linkage: `\"single\"`, `\"complete\"`, `\"average\"`, or `\"ward\"`."
  def hierarchical_cluster(data, n_features, n_clusters, linkage \\ "average", metric \\ "euclidean")
      when is_list(data) and is_integer(n_features) and is_integer(n_clusters)
      and is_binary(linkage) and is_binary(metric),
      do: nif_call(fn -> Native.hierarchical_cluster(data, n_features, n_clusters, linkage, metric) end)

  @doc "Principal component analysis. Returns `{:ok, %PcaResult{}}`."
  def pca(data, n_features, n_components)
      when is_list(data) and is_integer(n_features) and is_integer(n_components),
      do: nif_call(fn -> Native.pca(data, n_features, n_components) end)

  @doc "t-SNE dimensionality reduction. Returns `{:ok, %TsneResult{}}`."
  def tsne(data, n_features, n_components \\ 2, perplexity \\ 30.0, n_iter \\ 1000)
      when is_list(data) and is_integer(n_features)
      and is_integer(n_components) and is_number(perplexity) and is_integer(n_iter),
      do: nif_call(fn -> Native.tsne(data, n_features, n_components, perplexity, n_iter) end)

  @doc "UMAP dimensionality reduction. Returns `{:ok, %UmapResult{}}`."
  def umap(data, n_features, n_components \\ 2, n_neighbors \\ 15, min_dist \\ 0.1,
           n_epochs \\ 200, metric \\ "euclidean", seed \\ 42)
      when is_list(data) and is_integer(n_features),
      do: nif_call(fn -> Native.umap(data, n_features, n_components, n_neighbors, min_dist, n_epochs, metric, seed) end)

  @doc "Compute normalized k-mer frequency embedding for a sequence."
  def kmer_embedding(sequence, k, alphabet \\ "dna")
      when is_binary(sequence) and is_integer(k) and is_binary(alphabet),
      do: nif_call(fn -> Native.kmer_embedding(sequence, k, alphabet) end)

  @doc "Batch k-mer frequency embeddings for multiple sequences."
  def batch_embed(sequences, k, alphabet \\ "dna")
      when is_list(sequences) and is_integer(k) and is_binary(alphabet),
      do: nif_call(fn -> Native.batch_embed(sequences, k, alphabet) end)

  @doc "Compute pairwise distance matrix (condensed upper-triangle)."
  def pairwise_distances(data, n_features, metric \\ "euclidean")
      when is_list(data) and is_integer(n_features) and is_binary(metric),
      do: nif_call(fn -> Native.pairwise_distances(data, n_features, metric) end)

  # --- Classification & Regression (new) ------------------------------------

  @doc "K-nearest neighbor classification. Returns predicted label."
  def knn_classify(data, n_features, k, metric, labels, query)
      when is_list(data) and is_integer(n_features) and is_integer(k)
      and is_binary(metric) and is_list(labels) and is_list(query),
      do: nif_call(fn -> Native.knn_classify(data, n_features, k, metric, labels, query) end)

  @doc "Fit a linear regression model. Returns `{:ok, %LinearRegressionResult{}}`."
  def linear_regression_fit(data, n_features, targets)
      when is_list(data) and is_integer(n_features) and is_list(targets),
      do: nif_call(fn -> Native.linear_regression_fit(data, n_features, targets) end)

  @doc "Predict using linear regression weights and bias."
  def linear_regression_predict(weights, bias, queries, n_features)
      when is_list(weights) and is_number(bias) and is_list(queries) and is_integer(n_features),
      do: nif_call(fn -> Native.linear_regression_predict(weights, bias, queries, n_features) end)

  @doc "Fit a random forest classifier. Returns serialized model as binary."
  def random_forest_fit(data, n_features, labels, n_trees \\ 10, max_depth \\ 5, seed \\ 42)
      when is_list(data) and is_integer(n_features) and is_list(labels)
      and is_integer(n_trees) and is_integer(max_depth) and is_integer(seed),
      do: nif_call(fn -> Native.random_forest_fit(data, n_features, labels, n_trees, max_depth, seed) end)

  @doc "Predict class label using a serialized random forest model."
  def random_forest_predict(model_data, sample, n_features)
      when is_binary(model_data) and is_list(sample) and is_integer(n_features),
      do: nif_call(fn -> Native.random_forest_predict(model_data, sample, n_features) end)

  # --- HMM (new) ------------------------------------------------------------

  @doc "HMM Viterbi decoding. Returns `{:ok, {most_likely_path, log_probability}}`."
  def hmm_viterbi(n_states, n_symbols, initial, transition, emission, observations)
      when is_integer(n_states) and is_integer(n_symbols)
      and is_list(initial) and is_list(transition) and is_list(emission) and is_list(observations),
      do: nif_call(fn -> Native.hmm_viterbi(n_states, n_symbols, initial, transition, emission, observations) end)

  @doc "HMM forward algorithm. Returns log-probability of observation sequence."
  def hmm_forward(n_states, n_symbols, initial, transition, emission, observations)
      when is_integer(n_states) and is_integer(n_symbols)
      and is_list(initial) and is_list(transition) and is_list(emission) and is_list(observations),
      do: nif_call(fn -> Native.hmm_forward(n_states, n_symbols, initial, transition, emission, observations) end)

  # --- Normalization & Evaluation (new) -------------------------------------

  @doc "Min-max normalize data to [0, 1]."
  def normalize_min_max(data) when is_list(data),
    do: nif_call(fn -> Native.normalize_min_max(data) end)

  @doc "Z-score normalize data (zero mean, unit variance)."
  def normalize_z_score(data) when is_list(data),
    do: nif_call(fn -> Native.normalize_z_score(data) end)

  @doc "Compute silhouette score for clustering quality."
  def silhouette_score(data, n_features, labels, metric \\ "euclidean")
      when is_list(data) and is_integer(n_features) and is_list(labels) and is_binary(metric),
      do: nif_call(fn -> Native.silhouette_score(data, n_features, labels, metric) end)

  @doc "Compute Jaccard similarity between two MinHash sketches."
  def minhash_jaccard(sketch_a, sketch_b) when is_list(sketch_a) and is_list(sketch_b),
    do: nif_call(fn -> Native.minhash_jaccard(sketch_a, sketch_b) end)

  # ===========================================================================
  # Chemistry — Small Molecules
  # ===========================================================================

  @doc "Parse a SMILES string and compute molecular properties. Returns `{:ok, %MolecularProperties{}}`."
  def smiles_properties(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.smiles_properties(smiles) end)

  @doc "Compute Morgan fingerprint as a byte vector."
  def smiles_fingerprint(smiles, radius \\ 2, nbits \\ 2048)
      when is_binary(smiles) and is_integer(radius) and is_integer(nbits),
      do: nif_call(fn -> Native.smiles_fingerprint(smiles, radius, nbits) end)

  @doc "Compute Tanimoto similarity between two SMILES via Morgan fingerprints."
  def tanimoto(smiles_a, smiles_b, radius \\ 2, nbits \\ 2048)
      when is_binary(smiles_a) and is_binary(smiles_b)
      and is_integer(radius) and is_integer(nbits),
      do: nif_call(fn -> Native.tanimoto(smiles_a, smiles_b, radius, nbits) end)

  @doc "Check if target SMILES contains the pattern as a substructure."
  def smiles_substructure(target, pattern)
      when is_binary(target) and is_binary(pattern),
      do: nif_call(fn -> Native.smiles_substructure(target, pattern) end)

  @doc "Generate canonical SMILES from input SMILES."
  def canonical_smiles(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.canonical_smiles(smiles) end)

  @doc "Parse an SDF file and return molecule summaries."
  def parse_sdf_file(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_sdf_file(path) end)

  @doc "Compute MACCS fingerprint as byte vector."
  def maccs_fingerprint(smiles) when is_binary(smiles),
    do: nif_call(fn -> Native.maccs_fingerprint(smiles) end)

  # ===========================================================================
  # Structures — PDB / mmCIF
  # ===========================================================================

  @doc "Parse PDB text and return structure info. Returns `{:ok, %PdbInfo{}}`."
  def pdb_info(pdb_text) when is_binary(pdb_text),
    do: nif_call(fn -> Native.pdb_info(pdb_text) end)

  @doc "Parse a PDB file from disk. Returns `{:ok, %PdbInfo{}}`."
  def pdb_file_info(path) when is_binary(path),
    do: nif_call(fn -> Native.pdb_file_info(path) end)

  @doc "Assign secondary structure (simplified DSSP) for a chain."
  def pdb_secondary_structure(pdb_text, chain_id)
      when is_binary(pdb_text) and is_binary(chain_id),
      do: nif_call(fn -> Native.pdb_secondary_structure(pdb_text, chain_id) end)

  @doc "Compute RMSD between CA atoms of two chains."
  def pdb_rmsd(pdb_a, pdb_b, chain_a, chain_b)
      when is_binary(pdb_a) and is_binary(pdb_b)
      and is_binary(chain_a) and is_binary(chain_b),
      do: nif_call(fn -> Native.pdb_rmsd(pdb_a, pdb_b, chain_a, chain_b) end)

  @doc "Parse mmCIF text and return structure info."
  def mmcif_info(mmcif_text) when is_binary(mmcif_text),
    do: nif_call(fn -> Native.mmcif_info(mmcif_text) end)

  @doc "Compute contact map for a chain within cutoff distance."
  def pdb_contact_map(pdb_text, chain_id, cutoff \\ 8.0)
      when is_binary(pdb_text) and is_binary(chain_id) and is_number(cutoff),
      do: nif_call(fn -> Native.pdb_contact_map(pdb_text, chain_id, cutoff) end)

  @doc "Kabsch superposition of CA atoms. Returns RMSD, rotation, and translation."
  def pdb_kabsch(pdb_a, pdb_b, chain_a, chain_b)
      when is_binary(pdb_a) and is_binary(pdb_b)
      and is_binary(chain_a) and is_binary(chain_b),
      do: nif_call(fn -> Native.pdb_kabsch(pdb_a, pdb_b, chain_a, chain_b) end)

  @doc "Compute Ramachandran phi/psi angles for all residues."
  def pdb_ramachandran(pdb_text) when is_binary(pdb_text),
    do: nif_call(fn -> Native.pdb_ramachandran(pdb_text) end)

  @doc "Analyze B-factor distribution across the structure."
  def pdb_bfactor_analysis(pdb_text) when is_binary(pdb_text),
    do: nif_call(fn -> Native.pdb_bfactor_analysis(pdb_text) end)

  @doc "Parse an mmCIF file from disk."
  def mmcif_file_info(path) when is_binary(path),
    do: nif_call(fn -> Native.mmcif_file_info(path) end)

  # ===========================================================================
  # Phylogenetics
  # ===========================================================================

  @doc "Parse a Newick string and return tree info. Returns `{:ok, %NewickInfo{}}`."
  def newick_info(newick) when is_binary(newick),
    do: nif_call(fn -> Native.newick_info(newick) end)

  @doc "Compute Robinson-Foulds distance between two Newick trees."
  def newick_robinson_foulds(newick_a, newick_b)
      when is_binary(newick_a) and is_binary(newick_b),
      do: nif_call(fn -> Native.newick_robinson_foulds(newick_a, newick_b) end)

  @doc """
  Compute evolutionary distance between two aligned sequences.

  Model is `"p"`, `"jc"`, or `"k2p"`.
  """
  def evolutionary_distance(seq_a, seq_b, model \\ "p")
      when is_binary(seq_a) and is_binary(seq_b) and is_binary(model),
      do: nif_call(fn -> Native.evolutionary_distance(seq_a, seq_b, model) end)

  @doc "Build a UPGMA tree from aligned sequences. Returns Newick string."
  def build_upgma(sequences, names, model \\ "p")
      when is_list(sequences) and is_list(names) and is_binary(model),
      do: nif_call(fn -> Native.build_upgma(sequences, names, model) end)

  @doc "Build a Neighbor-Joining tree from aligned sequences. Returns Newick string."
  def build_nj(sequences, names, model \\ "p")
      when is_list(sequences) and is_list(names) and is_binary(model),
      do: nif_call(fn -> Native.build_nj(sequences, names, model) end)

  @doc "Parse NEXUS format text and return taxa and tree data."
  def nexus_parse(nexus_text) when is_binary(nexus_text),
    do: nif_call(fn -> Native.nexus_parse(nexus_text) end)

  @doc "Write taxa and trees to NEXUS format string."
  def nexus_write(taxa, trees_newick) when is_list(taxa) and is_list(trees_newick),
    do: nif_call(fn -> Native.nexus_write(taxa, trees_newick) end)

  @doc "Compute normalized Robinson-Foulds distance (0.0-1.0)."
  def robinson_foulds_normalized(newick_a, newick_b)
      when is_binary(newick_a) and is_binary(newick_b),
      do: nif_call(fn -> Native.robinson_foulds_normalized(newick_a, newick_b) end)

  @doc "Compute bootstrap support values for tree branches."
  def bootstrap_support(sequences, tree_newick, n_replicates \\ 100, model \\ "p")
      when is_list(sequences) and is_binary(tree_newick)
      and is_integer(n_replicates) and is_binary(model),
      do: nif_call(fn -> Native.bootstrap_support(sequences, tree_newick, n_replicates, model) end)

  @doc "Ancestral state reconstruction using Fitch parsimony."
  def ancestral_reconstruction(tree_newick, leaf_states)
      when is_binary(tree_newick) and is_list(leaf_states),
      do: nif_call(fn -> Native.ancestral_reconstruction(tree_newick, leaf_states) end)

  @doc "Branch score distance between two trees."
  def branch_score_distance(newick_a, newick_b)
      when is_binary(newick_a) and is_binary(newick_b),
      do: nif_call(fn -> Native.branch_score_distance(newick_a, newick_b) end)

  # ===========================================================================
  # GPU
  # ===========================================================================

  @doc "Get GPU backend info. Returns `{:ok, %GpuInfo{}}`."
  def gpu_info, do: nif_call(fn -> Native.gpu_info() end)

  @doc "Compute pairwise distance matrix on GPU."
  def gpu_pairwise_distances(data, n, dim, metric \\ "euclidean")
      when is_list(data) and is_integer(n) and is_integer(dim) and is_binary(metric),
      do: nif_call(fn -> Native.gpu_pairwise_distances(data, n, dim, metric) end)

  @doc "Matrix multiplication on GPU (a: m*k, b: k*n -> result: m*n)."
  def gpu_matrix_multiply(a, b, m, k, n)
      when is_list(a) and is_list(b) and is_integer(m) and is_integer(k) and is_integer(n),
      do: nif_call(fn -> Native.gpu_matrix_multiply(a, b, m, k, n) end)

  @doc "Sum reduction on GPU."
  def gpu_reduce_sum(data) when is_list(data),
    do: nif_call(fn -> Native.gpu_reduce_sum(data) end)

  @doc "Batch z-score normalization on GPU (per-row)."
  def gpu_batch_z_score(data, n_rows, n_cols)
      when is_list(data) and is_integer(n_rows) and is_integer(n_cols),
      do: nif_call(fn -> Native.gpu_batch_z_score(data, n_rows, n_cols) end)

  # ===========================================================================
  # Internal
  # ===========================================================================

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

defmodule Cyanea.ComputeTest do
  use ExUnit.Case, async: false

  alias Cyanea.Compute

  @moduledoc """
  Tests for the Compute context.

  Since NIFs are compiled with `skip_compilation?: true` in dev/test,
  all NIF calls will return `{:error, :nif_not_loaded}`. These tests
  verify the wrapper's error handling, function signatures, and guard clauses.
  """

  # ===========================================================================
  # Sequence validation & operations
  # ===========================================================================

  describe "sequence functions" do
    test "validate_dna returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.validate_dna("ATCG")
    end

    test "validate_rna returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.validate_rna("AUCG")
    end

    test "validate_protein returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.validate_protein("MVLK")
    end

    test "dna_reverse_complement returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.dna_reverse_complement("ATCG")
    end

    test "dna_transcribe returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.dna_transcribe("ATCG")
    end

    test "dna_gc_content returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.dna_gc_content("GCGC")
    end

    test "rna_translate returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.rna_translate("AUGCGA")
    end

    test "sequence_kmers returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.sequence_kmers("ATCGATCG", 3)
    end

    test "protein_molecular_weight returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.protein_molecular_weight("MVLK")
    end
  end

  # --- Pattern matching (new) ------------------------------------------------

  describe "horspool_search" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.horspool_search("ATCGATCG", "ATC")
    end
  end

  describe "myers_search" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.myers_search("ATCGATCG", "ATC", 1)
    end
  end

  # --- FM-Index (new) --------------------------------------------------------

  describe "fm_index_build" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.fm_index_build("ATCGATCG")
    end
  end

  describe "fm_index_count" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.fm_index_count(<<0, 1, 2>>, "ATC")
    end
  end

  # --- ORF finding (new) -----------------------------------------------------

  describe "find_orfs" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.find_orfs("ATGATCGATCGTAA")
    end

    test "accepts min_length parameter" do
      assert {:error, :nif_not_loaded} = Compute.find_orfs("ATGATCGATCGTAA", 50)
    end
  end

  # --- MinHash (new) ---------------------------------------------------------

  describe "minhash_sketch" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.minhash_sketch("ATCGATCG", 3, 100)
    end
  end

  # ===========================================================================
  # File analysis
  # ===========================================================================

  describe "file analysis functions" do
    test "fasta_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.fasta_stats("/tmp/test.fasta")
    end

    test "fastq_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.fastq_stats("/tmp/test.fastq")
    end

    test "parse_fastq returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_fastq("/tmp/test.fastq")
    end

    test "csv_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.csv_info("/tmp/test.csv")
    end

    test "csv_preview returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.csv_preview("/tmp/test.csv")
    end

    test "csv_preview accepts limit parameter" do
      assert {:error, :nif_not_loaded} = Compute.csv_preview("/tmp/test.csv", 50)
    end
  end

  # ===========================================================================
  # File format stats (VCF / BED / GFF3)
  # ===========================================================================

  describe "file format stats" do
    test "vcf_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.vcf_stats("/tmp/test.vcf")
    end

    test "bed_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.bed_stats("/tmp/test.bed")
    end

    test "gff3_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gff3_stats("/tmp/test.gff3")
    end
  end

  # --- New file format parsers (new) -----------------------------------------

  describe "new file format parsers" do
    test "parse_vcf returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_vcf("/tmp/test.vcf")
    end

    test "parse_bed returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_bed("/tmp/test.bed")
    end

    test "parse_gff3 returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_gff3("/tmp/test.gff3")
    end

    test "sam_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.sam_stats("/tmp/test.sam")
    end

    test "bam_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.bam_stats("/tmp/test.bam")
    end

    test "parse_sam returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_sam("/tmp/test.sam")
    end

    test "parse_bam returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_bam("/tmp/test.bam")
    end

    test "parse_bed_intervals returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_bed_intervals("/tmp/test.bed")
    end
  end

  # ===========================================================================
  # Alignment
  # ===========================================================================

  describe "alignment functions" do
    test "align_dna returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.align_dna("ATCG", "ATCG")
    end

    test "align_dna accepts mode parameter" do
      assert {:error, :nif_not_loaded} = Compute.align_dna("ATCG", "ATCG", "global")
    end

    test "align_dna_custom returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.align_dna_custom("ATCG", "ATCG", "global", 2, -1, -5, -2)
    end

    test "align_protein returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.align_protein("MVLK", "MVLK")
    end

    test "align_protein accepts mode and matrix parameters" do
      assert {:error, :nif_not_loaded} = Compute.align_protein("MVLK", "MVLK", "local", "blosum45")
    end

    test "align_batch_dna returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.align_batch_dna([{"AT", "AT"}])
    end

    test "align_batch_dna accepts mode parameter" do
      assert {:error, :nif_not_loaded} = Compute.align_batch_dna([{"AT", "AT"}], "global")
    end
  end

  describe "progressive_msa" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.progressive_msa(["ATCG", "ATCG"])
    end

    test "accepts mode parameter" do
      assert {:error, :nif_not_loaded} = Compute.progressive_msa(["MVLK", "MVLK"], "protein")
    end
  end

  # --- Banded & POA (new) ----------------------------------------------------

  describe "banded_align_dna" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.banded_align_dna("ATCG", "ATCG")
    end

    test "accepts mode and bandwidth parameters" do
      assert {:error, :nif_not_loaded} = Compute.banded_align_dna("ATCG", "ATCG", "local", 20)
    end
  end

  describe "banded_score_only" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.banded_score_only("ATCG", "ATCG")
    end

    test "accepts mode and bandwidth parameters" do
      assert {:error, :nif_not_loaded} = Compute.banded_score_only("ATCG", "ATCG", "local", 20)
    end
  end

  describe "poa_consensus" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.poa_consensus(["ATCG", "ATCG", "ATCG"])
    end
  end

  # ===========================================================================
  # Statistics
  # ===========================================================================

  describe "statistics functions" do
    test "descriptive_stats returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.descriptive_stats([1.0, 2.0, 3.0])
    end

    test "pearson_correlation returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pearson_correlation([1.0, 2.0], [3.0, 4.0])
    end

    test "spearman_correlation returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.spearman_correlation([1.0, 2.0], [3.0, 4.0])
    end

    test "t_test_one_sample returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.t_test_one_sample([1.0, 2.0, 3.0])
    end

    test "t_test_one_sample accepts mu parameter" do
      assert {:error, :nif_not_loaded} = Compute.t_test_one_sample([1.0, 2.0, 3.0], 5.0)
    end

    test "t_test_two_sample returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.t_test_two_sample([1.0, 2.0], [3.0, 4.0])
    end

    test "t_test_two_sample accepts equal_var parameter" do
      assert {:error, :nif_not_loaded} = Compute.t_test_two_sample([1.0, 2.0], [3.0, 4.0], true)
    end

    test "mann_whitney_u returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.mann_whitney_u([1.0, 2.0], [3.0, 4.0])
    end

    test "p_adjust_bonferroni returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.p_adjust_bonferroni([0.01, 0.05])
    end

    test "p_adjust_bh returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.p_adjust_bh([0.01, 0.05])
    end
  end

  # --- Effect sizes & distributions (new) ------------------------------------

  describe "cohens_d" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.cohens_d([1.0, 2.0, 3.0], [4.0, 5.0, 6.0])
    end
  end

  describe "odds_ratio" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.odds_ratio(10, 20, 30, 40)
    end
  end

  describe "normal_cdf" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.normal_cdf(1.96)
    end

    test "accepts mu and sigma parameters" do
      assert {:error, :nif_not_loaded} = Compute.normal_cdf(1.96, 0.0, 1.0)
    end
  end

  describe "normal_pdf" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.normal_pdf(0.0)
    end

    test "accepts mu and sigma parameters" do
      assert {:error, :nif_not_loaded} = Compute.normal_pdf(0.0, 0.0, 1.0)
    end
  end

  describe "chi_squared_cdf" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.chi_squared_cdf(3.84, 1)
    end
  end

  describe "bayesian_beta_update" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.bayesian_beta_update(1.0, 1.0, 7, 10)
    end
  end

  # ===========================================================================
  # Omics
  # ===========================================================================

  describe "omics functions" do
    test "classify_variant returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.classify_variant("chr1", 100, "A", ["G"])
    end

    test "merge_genomic_intervals returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.merge_genomic_intervals(["chr1"], [0], [100])
    end

    test "genomic_coverage returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.genomic_coverage(["chr1"], [0], [100], "chr1")
    end

    test "expression_summary returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.expression_summary([[1.0]], ["gene1"], ["s1"])
    end

    test "log_transform_matrix returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.log_transform_matrix([[1.0, 2.0]])
    end

    test "log_transform_matrix accepts pseudocount parameter" do
      assert {:error, :nif_not_loaded} = Compute.log_transform_matrix([[1.0, 2.0]], 0.5)
    end
  end

  # ===========================================================================
  # Compression & Hashing
  # ===========================================================================

  describe "compression and hashing functions" do
    test "sha256 returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.sha256("hello")
    end

    test "sha256_file returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.sha256_file("/tmp/test.txt")
    end

    test "zstd_compress returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.zstd_compress("hello")
    end

    test "zstd_compress accepts level parameter" do
      assert {:error, :nif_not_loaded} = Compute.zstd_compress("hello", 10)
    end

    test "zstd_decompress returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.zstd_decompress(<<0, 1, 2>>)
    end

    test "gzip_compress returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gzip_compress("hello")
    end

    test "gzip_compress accepts level parameter" do
      assert {:error, :nif_not_loaded} = Compute.gzip_compress("hello", 9)
    end

    test "gzip_decompress returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gzip_decompress(<<0, 1, 2>>)
    end
  end

  # ===========================================================================
  # ML — Clustering
  # ===========================================================================

  describe "ML clustering" do
    test "kmeans returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.kmeans([0.0, 0.0, 1.0, 1.0], 2, 2)
    end

    test "kmeans accepts optional parameters" do
      assert {:error, :nif_not_loaded} = Compute.kmeans([0.0, 0.0, 1.0, 1.0], 2, 2, 50, 123)
    end

    test "dbscan returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.dbscan([0.0, 0.0, 1.0, 1.0], 2, 0.5, 2)
    end

    test "dbscan accepts metric parameter" do
      assert {:error, :nif_not_loaded} = Compute.dbscan([0.0, 0.0], 2, 0.5, 2, "cosine")
    end

    test "hierarchical_cluster returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.hierarchical_cluster([0.0, 0.0, 1.0, 1.0], 2, 2)
    end

    test "hierarchical_cluster accepts linkage and metric parameters" do
      assert {:error, :nif_not_loaded} = Compute.hierarchical_cluster([0.0, 0.0, 1.0, 1.0], 2, 2, "single", "manhattan")
    end
  end

  # ===========================================================================
  # ML — Dimensionality Reduction
  # ===========================================================================

  describe "ML dimensionality reduction" do
    test "pca returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pca([1.0, 2.0, 3.0, 4.0], 2, 1)
    end

    test "tsne returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.tsne([1.0, 2.0, 3.0, 4.0], 2)
    end

    test "tsne accepts optional parameters" do
      assert {:error, :nif_not_loaded} = Compute.tsne([1.0, 2.0, 3.0, 4.0], 2, 2, 5.0, 100)
    end

    test "umap returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.umap([1.0, 2.0, 3.0, 4.0], 2)
    end

    test "umap accepts optional parameters" do
      assert {:error, :nif_not_loaded} = Compute.umap([1.0, 2.0, 3.0, 4.0], 2, 2, 15, 0.1, 200, "euclidean", 42)
    end
  end

  # ===========================================================================
  # ML — Embeddings and Distances
  # ===========================================================================

  describe "ML embeddings and distances" do
    test "kmer_embedding returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.kmer_embedding("ATCGATCG", 3)
    end

    test "kmer_embedding accepts alphabet parameter" do
      assert {:error, :nif_not_loaded} = Compute.kmer_embedding("MVLKGAA", 2, "protein")
    end

    test "batch_embed returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.batch_embed(["ATCG", "GCTA"], 3)
    end

    test "batch_embed accepts alphabet parameter" do
      assert {:error, :nif_not_loaded} = Compute.batch_embed(["ATCG", "GCTA"], 3, "dna")
    end

    test "pairwise_distances returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pairwise_distances([0.0, 0.0, 1.0, 1.0], 2)
    end

    test "pairwise_distances accepts metric parameter" do
      assert {:error, :nif_not_loaded} = Compute.pairwise_distances([0.0, 0.0], 2, "manhattan")
    end
  end

  # ===========================================================================
  # ML — Classification & Regression (new)
  # ===========================================================================

  describe "knn_classify" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.knn_classify(
        [0.0, 0.0, 1.0, 1.0], 2, 1, "euclidean", [0, 1], [0.5, 0.5]
      )
    end
  end

  describe "linear_regression_fit" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.linear_regression_fit([1.0, 2.0, 3.0, 4.0], 2, [1.0, 2.0])
    end
  end

  describe "linear_regression_predict" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.linear_regression_predict([0.5, 0.3], 0.1, [1.0, 2.0], 2)
    end
  end

  describe "random_forest_fit" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.random_forest_fit([1.0, 2.0, 3.0, 4.0], 2, [0, 1])
    end

    test "accepts optional parameters" do
      assert {:error, :nif_not_loaded} = Compute.random_forest_fit([1.0, 2.0, 3.0, 4.0], 2, [0, 1], 20, 10, 99)
    end
  end

  describe "random_forest_predict" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.random_forest_predict(<<0, 1, 2>>, [1.0, 2.0], 2)
    end
  end

  # ===========================================================================
  # ML — HMM (new)
  # ===========================================================================

  describe "hmm_viterbi" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.hmm_viterbi(
        2, 2,
        [0.5, 0.5],
        [0.7, 0.3, 0.4, 0.6],
        [0.9, 0.1, 0.2, 0.8],
        [0, 1, 0]
      )
    end
  end

  describe "hmm_forward" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.hmm_forward(
        2, 2,
        [0.5, 0.5],
        [0.7, 0.3, 0.4, 0.6],
        [0.9, 0.1, 0.2, 0.8],
        [0, 1, 0]
      )
    end
  end

  # ===========================================================================
  # ML — Normalization & Evaluation (new)
  # ===========================================================================

  describe "normalize_min_max" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.normalize_min_max([1.0, 2.0, 3.0])
    end
  end

  describe "normalize_z_score" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.normalize_z_score([1.0, 2.0, 3.0])
    end
  end

  describe "silhouette_score" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.silhouette_score(
        [0.0, 0.0, 1.0, 1.0, 5.0, 5.0], 2, [0, 0, 1]
      )
    end

    test "accepts metric parameter" do
      assert {:error, :nif_not_loaded} = Compute.silhouette_score(
        [0.0, 0.0, 1.0, 1.0], 2, [0, 1], "cosine"
      )
    end
  end

  describe "minhash_jaccard" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.minhash_jaccard([1, 2, 3, 4], [2, 3, 4, 5])
    end
  end

  # ===========================================================================
  # Chemistry
  # ===========================================================================

  describe "chemistry functions" do
    test "smiles_properties returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.smiles_properties("CCO")
    end

    test "smiles_fingerprint returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.smiles_fingerprint("CCO")
    end

    test "smiles_fingerprint accepts radius and nbits" do
      assert {:error, :nif_not_loaded} = Compute.smiles_fingerprint("CCO", 3, 1024)
    end

    test "tanimoto returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.tanimoto("CCO", "CC")
    end

    test "tanimoto accepts radius and nbits" do
      assert {:error, :nif_not_loaded} = Compute.tanimoto("CCO", "CC", 3, 1024)
    end

    test "smiles_substructure returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.smiles_substructure("c1ccccc1O", "c1ccccc1")
    end
  end

  # --- New chemistry functions (new) -----------------------------------------

  describe "canonical_smiles" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.canonical_smiles("C(C)O")
    end
  end

  describe "parse_sdf_file" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.parse_sdf_file("/tmp/test.sdf")
    end
  end

  describe "maccs_fingerprint" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.maccs_fingerprint("CCO")
    end
  end

  # ===========================================================================
  # Structures
  # ===========================================================================

  @sample_pdb "HEADER    TEST\nATOM      1  CA  ALA A   1       1.0   2.0   3.0  1.00  0.00           C\nEND\n"

  describe "structure functions" do
    test "pdb_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_info(@sample_pdb)
    end

    test "pdb_file_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_file_info("/tmp/test.pdb")
    end

    test "pdb_secondary_structure returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_secondary_structure(@sample_pdb, "A")
    end

    test "pdb_rmsd returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_rmsd(@sample_pdb, @sample_pdb, "A", "A")
    end
  end

  # --- New struct functions (new) --------------------------------------------

  describe "mmcif_info" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.mmcif_info("data_test\n_entry.id TEST\n")
    end
  end

  describe "pdb_contact_map" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_contact_map(@sample_pdb, "A")
    end

    test "accepts cutoff parameter" do
      assert {:error, :nif_not_loaded} = Compute.pdb_contact_map(@sample_pdb, "A", 10.0)
    end
  end

  describe "pdb_kabsch" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_kabsch(@sample_pdb, @sample_pdb, "A", "A")
    end
  end

  describe "pdb_ramachandran" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_ramachandran(@sample_pdb)
    end
  end

  describe "pdb_bfactor_analysis" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pdb_bfactor_analysis(@sample_pdb)
    end
  end

  describe "mmcif_file_info" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.mmcif_file_info("/tmp/test.cif")
    end
  end

  # ===========================================================================
  # Phylogenetics
  # ===========================================================================

  describe "phylogenetics functions" do
    test "newick_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.newick_info("((A:0.1,B:0.2):0.3,C:0.4);")
    end

    test "newick_robinson_foulds returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.newick_robinson_foulds("((A,B),C);", "((A,C),B);")
    end

    test "evolutionary_distance returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.evolutionary_distance("ATCGATCG", "ATCAATCG")
    end

    test "evolutionary_distance accepts model parameter" do
      assert {:error, :nif_not_loaded} = Compute.evolutionary_distance("ATCG", "ATCA", "k2p")
    end

    test "build_upgma returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.build_upgma(["ATCG", "ATCG"], ["A", "B"])
    end

    test "build_upgma accepts model parameter" do
      assert {:error, :nif_not_loaded} = Compute.build_upgma(["ATCG", "ATCG"], ["A", "B"], "jc")
    end

    test "build_nj returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.build_nj(["ATCG", "ATCG"], ["A", "B"])
    end
  end

  # --- New phylo functions (new) ---------------------------------------------

  describe "nexus_parse" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.nexus_parse("#NEXUS\nBEGIN TAXA;")
    end
  end

  describe "nexus_write" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.nexus_write(["A", "B"], ["((A,B));"])
    end
  end

  describe "robinson_foulds_normalized" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.robinson_foulds_normalized("((A,B),C);", "((A,C),B);")
    end
  end

  describe "bootstrap_support" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.bootstrap_support(["ATCG", "ATCA"], "((A,B));")
    end

    test "accepts n_replicates and model parameters" do
      assert {:error, :nif_not_loaded} = Compute.bootstrap_support(["ATCG", "ATCA"], "((A,B));", 50, "jc")
    end
  end

  describe "ancestral_reconstruction" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.ancestral_reconstruction("((A,B),C);", ["A", "G", "A"])
    end
  end

  describe "branch_score_distance" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.branch_score_distance(
        "((A:0.1,B:0.2):0.3,C:0.4);", "((A:0.2,B:0.1):0.3,C:0.4);"
      )
    end
  end

  # ===========================================================================
  # GPU
  # ===========================================================================

  describe "gpu functions" do
    test "gpu_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gpu_info()
    end
  end

  # --- New GPU functions (new) -----------------------------------------------

  describe "gpu_pairwise_distances" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gpu_pairwise_distances([0.0, 0.0, 1.0, 1.0], 2, 2)
    end

    test "accepts metric parameter" do
      assert {:error, :nif_not_loaded} = Compute.gpu_pairwise_distances([0.0, 0.0, 1.0, 1.0], 2, 2, "manhattan")
    end
  end

  describe "gpu_matrix_multiply" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gpu_matrix_multiply(
        [1.0, 2.0, 3.0, 4.0],
        [5.0, 6.0, 7.0, 8.0],
        2, 2, 2
      )
    end
  end

  describe "gpu_reduce_sum" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gpu_reduce_sum([1.0, 2.0, 3.0])
    end
  end

  describe "gpu_batch_z_score" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gpu_batch_z_score([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3)
    end
  end

  # ===========================================================================
  # Guard clauses — existing functions
  # ===========================================================================

  describe "guard clauses — sequence functions" do
    test "validate_dna rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.validate_dna(123) end
    end

    test "validate_rna rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.validate_rna(123) end
    end

    test "validate_protein rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.validate_protein(123) end
    end

    test "dna_reverse_complement rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.dna_reverse_complement(123) end
    end

    test "dna_transcribe rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.dna_transcribe(123) end
    end

    test "dna_gc_content rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.dna_gc_content(123) end
    end

    test "rna_translate rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.rna_translate(123) end
    end

    test "sequence_kmers rejects non-binary data" do
      assert_raise FunctionClauseError, fn -> Compute.sequence_kmers(123, 3) end
    end

    test "sequence_kmers rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.sequence_kmers("ATCG", "3") end
    end

    test "protein_molecular_weight rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.protein_molecular_weight(123) end
    end
  end

  describe "guard clauses — new sequence functions" do
    test "horspool_search rejects non-binary text" do
      assert_raise FunctionClauseError, fn -> Compute.horspool_search(123, "ATC") end
    end

    test "horspool_search rejects non-binary pattern" do
      assert_raise FunctionClauseError, fn -> Compute.horspool_search("ATCG", 123) end
    end

    test "myers_search rejects non-binary text" do
      assert_raise FunctionClauseError, fn -> Compute.myers_search(123, "ATC", 1) end
    end

    test "myers_search rejects non-integer max_dist" do
      assert_raise FunctionClauseError, fn -> Compute.myers_search("ATCG", "ATC", "1") end
    end

    test "fm_index_build rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.fm_index_build(123) end
    end

    test "fm_index_count rejects non-binary index_data" do
      assert_raise FunctionClauseError, fn -> Compute.fm_index_count(123, "ATC") end
    end

    test "fm_index_count rejects non-binary pattern" do
      assert_raise FunctionClauseError, fn -> Compute.fm_index_count(<<0>>, 123) end
    end

    test "find_orfs rejects non-binary seq" do
      assert_raise FunctionClauseError, fn -> Compute.find_orfs(123) end
    end

    test "find_orfs rejects non-integer min_length" do
      assert_raise FunctionClauseError, fn -> Compute.find_orfs("ATCG", "100") end
    end

    test "minhash_sketch rejects non-binary seq" do
      assert_raise FunctionClauseError, fn -> Compute.minhash_sketch(123, 3, 100) end
    end

    test "minhash_sketch rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.minhash_sketch("ATCG", "3", 100) end
    end

    test "minhash_sketch rejects non-integer sketch_size" do
      assert_raise FunctionClauseError, fn -> Compute.minhash_sketch("ATCG", 3, "100") end
    end
  end

  describe "guard clauses — file functions" do
    test "fasta_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.fasta_stats(123) end
    end

    test "fastq_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.fastq_stats(123) end
    end

    test "csv_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.csv_info(123) end
    end

    test "vcf_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.vcf_stats(123) end
    end

    test "bed_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.bed_stats(123) end
    end

    test "gff3_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.gff3_stats(123) end
    end

    test "parse_vcf rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_vcf(123) end
    end

    test "parse_bed rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_bed(123) end
    end

    test "parse_gff3 rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_gff3(123) end
    end

    test "sam_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.sam_stats(123) end
    end

    test "bam_stats rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.bam_stats(123) end
    end

    test "parse_sam rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_sam(123) end
    end

    test "parse_bam rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_bam(123) end
    end

    test "parse_bed_intervals rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_bed_intervals(123) end
    end

    test "parse_sdf_file rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.parse_sdf_file(123) end
    end
  end

  describe "guard clauses — alignment functions" do
    test "align_dna rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Compute.align_dna(123, "ATCG") end
    end

    test "align_dna rejects non-binary target" do
      assert_raise FunctionClauseError, fn -> Compute.align_dna("ATCG", 123) end
    end

    test "align_dna rejects non-binary mode" do
      assert_raise FunctionClauseError, fn -> Compute.align_dna("ATCG", "ATCG", 123) end
    end

    test "align_batch_dna rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.align_batch_dna("not_a_list") end
    end

    test "progressive_msa rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.progressive_msa("not_a_list") end
    end

    test "progressive_msa rejects non-binary mode" do
      assert_raise FunctionClauseError, fn -> Compute.progressive_msa(["ATCG"], 123) end
    end

    test "banded_align_dna rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Compute.banded_align_dna(123, "ATCG") end
    end

    test "banded_align_dna rejects non-integer bandwidth" do
      assert_raise FunctionClauseError, fn -> Compute.banded_align_dna("ATCG", "ATCG", "global", "50") end
    end

    test "banded_score_only rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Compute.banded_score_only(123, "ATCG") end
    end

    test "poa_consensus rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.poa_consensus("not_a_list") end
    end
  end

  describe "guard clauses — statistics functions" do
    test "descriptive_stats rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.descriptive_stats("not a list") end
    end

    test "pearson_correlation rejects non-list x" do
      assert_raise FunctionClauseError, fn -> Compute.pearson_correlation("not", [1.0]) end
    end

    test "spearman_correlation rejects non-list y" do
      assert_raise FunctionClauseError, fn -> Compute.spearman_correlation([1.0], "not") end
    end

    test "t_test_one_sample rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.t_test_one_sample("not a list") end
    end

    test "t_test_two_sample rejects non-list x" do
      assert_raise FunctionClauseError, fn -> Compute.t_test_two_sample("not", [1.0]) end
    end

    test "mann_whitney_u rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.mann_whitney_u("not", [1.0]) end
    end

    test "p_adjust_bonferroni rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.p_adjust_bonferroni("not a list") end
    end

    test "p_adjust_bh rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.p_adjust_bh("not a list") end
    end
  end

  describe "guard clauses — new statistics functions" do
    test "cohens_d rejects non-list group1" do
      assert_raise FunctionClauseError, fn -> Compute.cohens_d("not", [1.0]) end
    end

    test "cohens_d rejects non-list group2" do
      assert_raise FunctionClauseError, fn -> Compute.cohens_d([1.0], "not") end
    end

    test "odds_ratio rejects non-integer a" do
      assert_raise FunctionClauseError, fn -> Compute.odds_ratio("10", 20, 30, 40) end
    end

    test "odds_ratio rejects non-integer b" do
      assert_raise FunctionClauseError, fn -> Compute.odds_ratio(10, "20", 30, 40) end
    end

    test "normal_cdf rejects non-number x" do
      assert_raise FunctionClauseError, fn -> Compute.normal_cdf("1.96") end
    end

    test "normal_pdf rejects non-number x" do
      assert_raise FunctionClauseError, fn -> Compute.normal_pdf("0.0") end
    end

    test "chi_squared_cdf rejects non-number x" do
      assert_raise FunctionClauseError, fn -> Compute.chi_squared_cdf("3.84", 1) end
    end

    test "chi_squared_cdf rejects non-number df" do
      assert_raise FunctionClauseError, fn -> Compute.chi_squared_cdf(3.84, "1") end
    end

    test "bayesian_beta_update rejects non-number alpha" do
      assert_raise FunctionClauseError, fn -> Compute.bayesian_beta_update("1", 1.0, 7, 10) end
    end

    test "bayesian_beta_update rejects non-integer successes" do
      assert_raise FunctionClauseError, fn -> Compute.bayesian_beta_update(1.0, 1.0, "7", 10) end
    end
  end

  describe "guard clauses — ML functions" do
    test "kmeans rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.kmeans("not a list", 2, 2) end
    end

    test "kmeans rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.kmeans([1.0], "2", 2) end
    end

    test "kmeans rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.kmeans([1.0], 2, "2") end
    end

    test "dbscan rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.dbscan("not", 2, 0.5, 2) end
    end

    test "dbscan rejects non-number eps" do
      assert_raise FunctionClauseError, fn -> Compute.dbscan([1.0], 1, "bad", 2) end
    end

    test "dbscan rejects non-integer min_samples" do
      assert_raise FunctionClauseError, fn -> Compute.dbscan([1.0], 1, 0.5, "2") end
    end

    test "dbscan rejects non-binary metric" do
      assert_raise FunctionClauseError, fn -> Compute.dbscan([1.0], 1, 0.5, 2, 123) end
    end

    test "pca rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.pca("not", 1, 1) end
    end

    test "pca rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.pca([1.0], "1", 1) end
    end

    test "pca rejects non-integer n_components" do
      assert_raise FunctionClauseError, fn -> Compute.pca([1.0], 1, "2") end
    end

    test "tsne rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.tsne("not", 2) end
    end

    test "tsne rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.tsne([1.0], "2") end
    end

    test "kmer_embedding rejects non-binary sequence" do
      assert_raise FunctionClauseError, fn -> Compute.kmer_embedding(123, 3) end
    end

    test "kmer_embedding rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.kmer_embedding("ATCG", "3") end
    end

    test "batch_embed rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Compute.batch_embed("not", 3) end
    end

    test "batch_embed rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.batch_embed(["ATCG"], "3") end
    end

    test "pairwise_distances rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.pairwise_distances("not", 2) end
    end

    test "pairwise_distances rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.pairwise_distances([1.0], "2") end
    end
  end

  describe "guard clauses — new ML functions" do
    test "hierarchical_cluster rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.hierarchical_cluster("not", 2, 2) end
    end

    test "hierarchical_cluster rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.hierarchical_cluster([1.0], "2", 2) end
    end

    test "hierarchical_cluster rejects non-integer n_clusters" do
      assert_raise FunctionClauseError, fn -> Compute.hierarchical_cluster([1.0], 2, "2") end
    end

    test "hierarchical_cluster rejects non-binary linkage" do
      assert_raise FunctionClauseError, fn -> Compute.hierarchical_cluster([1.0], 2, 2, 123) end
    end

    test "knn_classify rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.knn_classify("not", 2, 1, "euclidean", [0], [0.5]) end
    end

    test "knn_classify rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.knn_classify([1.0], 2, "1", "euclidean", [0], [0.5]) end
    end

    test "knn_classify rejects non-list labels" do
      assert_raise FunctionClauseError, fn -> Compute.knn_classify([1.0], 2, 1, "euclidean", "not", [0.5]) end
    end

    test "knn_classify rejects non-list query" do
      assert_raise FunctionClauseError, fn -> Compute.knn_classify([1.0], 2, 1, "euclidean", [0], "not") end
    end

    test "linear_regression_fit rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_fit("not", 2, [1.0]) end
    end

    test "linear_regression_fit rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_fit([1.0], "2", [1.0]) end
    end

    test "linear_regression_fit rejects non-list targets" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_fit([1.0], 2, "not") end
    end

    test "linear_regression_predict rejects non-list weights" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_predict("not", 0.1, [1.0], 2) end
    end

    test "linear_regression_predict rejects non-number bias" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_predict([0.5], "0.1", [1.0], 2) end
    end

    test "linear_regression_predict rejects non-list queries" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_predict([0.5], 0.1, "not", 2) end
    end

    test "linear_regression_predict rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.linear_regression_predict([0.5], 0.1, [1.0], "2") end
    end

    test "random_forest_fit rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.random_forest_fit("not", 2, [0]) end
    end

    test "random_forest_fit rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.random_forest_fit([1.0], "2", [0]) end
    end

    test "random_forest_fit rejects non-list labels" do
      assert_raise FunctionClauseError, fn -> Compute.random_forest_fit([1.0], 2, "not") end
    end

    test "random_forest_predict rejects non-binary model_data" do
      assert_raise FunctionClauseError, fn -> Compute.random_forest_predict(123, [1.0], 2) end
    end

    test "random_forest_predict rejects non-list sample" do
      assert_raise FunctionClauseError, fn -> Compute.random_forest_predict(<<0>>, "not", 2) end
    end

    test "random_forest_predict rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.random_forest_predict(<<0>>, [1.0], "2") end
    end

    test "hmm_viterbi rejects non-integer n_states" do
      assert_raise FunctionClauseError, fn ->
        Compute.hmm_viterbi("2", 2, [0.5], [0.5], [0.5], [0])
      end
    end

    test "hmm_viterbi rejects non-list initial" do
      assert_raise FunctionClauseError, fn ->
        Compute.hmm_viterbi(2, 2, "not", [0.5], [0.5], [0])
      end
    end

    test "hmm_forward rejects non-integer n_symbols" do
      assert_raise FunctionClauseError, fn ->
        Compute.hmm_forward(2, "2", [0.5], [0.5], [0.5], [0])
      end
    end

    test "hmm_forward rejects non-list observations" do
      assert_raise FunctionClauseError, fn ->
        Compute.hmm_forward(2, 2, [0.5], [0.5], [0.5], "not")
      end
    end

    test "normalize_min_max rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.normalize_min_max("not") end
    end

    test "normalize_z_score rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.normalize_z_score("not") end
    end

    test "silhouette_score rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.silhouette_score("not", 2, [0]) end
    end

    test "silhouette_score rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.silhouette_score([1.0], "2", [0]) end
    end

    test "silhouette_score rejects non-list labels" do
      assert_raise FunctionClauseError, fn -> Compute.silhouette_score([1.0], 2, "not") end
    end

    test "minhash_jaccard rejects non-list sketch_a" do
      assert_raise FunctionClauseError, fn -> Compute.minhash_jaccard("not", [1]) end
    end

    test "minhash_jaccard rejects non-list sketch_b" do
      assert_raise FunctionClauseError, fn -> Compute.minhash_jaccard([1], "not") end
    end
  end

  describe "guard clauses — chemistry functions" do
    test "smiles_properties rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.smiles_properties(123) end
    end

    test "smiles_fingerprint rejects non-binary smiles" do
      assert_raise FunctionClauseError, fn -> Compute.smiles_fingerprint(123) end
    end

    test "tanimoto rejects non-binary smiles_a" do
      assert_raise FunctionClauseError, fn -> Compute.tanimoto(123, "CC") end
    end

    test "tanimoto rejects non-binary smiles_b" do
      assert_raise FunctionClauseError, fn -> Compute.tanimoto("CCO", 123) end
    end

    test "smiles_substructure rejects non-binary target" do
      assert_raise FunctionClauseError, fn -> Compute.smiles_substructure(123, "c1ccccc1") end
    end

    test "smiles_substructure rejects non-binary pattern" do
      assert_raise FunctionClauseError, fn -> Compute.smiles_substructure("c1ccccc1O", 123) end
    end

    test "canonical_smiles rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.canonical_smiles(123) end
    end

    test "maccs_fingerprint rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.maccs_fingerprint(123) end
    end
  end

  describe "guard clauses — structure functions" do
    test "pdb_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_info(123) end
    end

    test "pdb_file_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_file_info(123) end
    end

    test "pdb_secondary_structure rejects non-binary pdb_text" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_secondary_structure(123, "A") end
    end

    test "pdb_secondary_structure rejects non-binary chain_id" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_secondary_structure("pdb", 123) end
    end

    test "pdb_rmsd rejects non-binary pdb_a" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_rmsd(123, "pdb", "A", "A") end
    end

    test "mmcif_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.mmcif_info(123) end
    end

    test "pdb_contact_map rejects non-binary pdb_text" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_contact_map(123, "A") end
    end

    test "pdb_contact_map rejects non-binary chain_id" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_contact_map("pdb", 123) end
    end

    test "pdb_kabsch rejects non-binary pdb_a" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_kabsch(123, "pdb", "A", "A") end
    end

    test "pdb_ramachandran rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_ramachandran(123) end
    end

    test "pdb_bfactor_analysis rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_bfactor_analysis(123) end
    end

    test "mmcif_file_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.mmcif_file_info(123) end
    end
  end

  describe "guard clauses — phylogenetics functions" do
    test "newick_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.newick_info(123) end
    end

    test "newick_robinson_foulds rejects non-binary newick_a" do
      assert_raise FunctionClauseError, fn -> Compute.newick_robinson_foulds(123, "((A,B),C);") end
    end

    test "evolutionary_distance rejects non-binary seq_a" do
      assert_raise FunctionClauseError, fn -> Compute.evolutionary_distance(123, "ATCG") end
    end

    test "evolutionary_distance rejects non-binary model" do
      assert_raise FunctionClauseError, fn -> Compute.evolutionary_distance("ATCG", "ATCG", 123) end
    end

    test "build_upgma rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Compute.build_upgma("ATCG", ["A"], "p") end
    end

    test "build_upgma rejects non-list names" do
      assert_raise FunctionClauseError, fn -> Compute.build_upgma(["ATCG"], "A", "p") end
    end

    test "build_nj rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Compute.build_nj("ATCG", ["A"]) end
    end

    test "nexus_parse rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.nexus_parse(123) end
    end

    test "nexus_write rejects non-list taxa" do
      assert_raise FunctionClauseError, fn -> Compute.nexus_write("A", ["((A,B));"]) end
    end

    test "nexus_write rejects non-list trees_newick" do
      assert_raise FunctionClauseError, fn -> Compute.nexus_write(["A"], "((A,B));") end
    end

    test "robinson_foulds_normalized rejects non-binary newick_a" do
      assert_raise FunctionClauseError, fn -> Compute.robinson_foulds_normalized(123, "((A,B),C);") end
    end

    test "bootstrap_support rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Compute.bootstrap_support("ATCG", "((A,B));") end
    end

    test "bootstrap_support rejects non-binary tree_newick" do
      assert_raise FunctionClauseError, fn -> Compute.bootstrap_support(["ATCG"], 123) end
    end

    test "ancestral_reconstruction rejects non-binary tree_newick" do
      assert_raise FunctionClauseError, fn -> Compute.ancestral_reconstruction(123, ["A"]) end
    end

    test "ancestral_reconstruction rejects non-list leaf_states" do
      assert_raise FunctionClauseError, fn -> Compute.ancestral_reconstruction("((A,B));", "A") end
    end

    test "branch_score_distance rejects non-binary newick_a" do
      assert_raise FunctionClauseError, fn -> Compute.branch_score_distance(123, "((A,B));") end
    end

    test "branch_score_distance rejects non-binary newick_b" do
      assert_raise FunctionClauseError, fn -> Compute.branch_score_distance("((A,B));", 123) end
    end
  end

  describe "guard clauses — compression functions" do
    test "sha256 rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.sha256(123) end
    end

    test "sha256_file rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.sha256_file(123) end
    end

    test "zstd_compress rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.zstd_compress(123) end
    end

    test "zstd_decompress rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.zstd_decompress(123) end
    end

    test "gzip_compress rejects non-binary data" do
      assert_raise FunctionClauseError, fn -> Compute.gzip_compress(123) end
    end

    test "gzip_compress rejects non-integer level" do
      assert_raise FunctionClauseError, fn -> Compute.gzip_compress("hello", "6") end
    end

    test "gzip_decompress rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.gzip_decompress(123) end
    end
  end

  describe "guard clauses — GPU functions" do
    test "gpu_pairwise_distances rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_pairwise_distances("not", 2, 2) end
    end

    test "gpu_pairwise_distances rejects non-integer n" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_pairwise_distances([1.0], "2", 2) end
    end

    test "gpu_pairwise_distances rejects non-integer dim" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_pairwise_distances([1.0], 2, "2") end
    end

    test "gpu_pairwise_distances rejects non-binary metric" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_pairwise_distances([1.0], 2, 2, 123) end
    end

    test "gpu_matrix_multiply rejects non-list a" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_matrix_multiply("not", [1.0], 2, 2, 2) end
    end

    test "gpu_matrix_multiply rejects non-list b" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_matrix_multiply([1.0], "not", 2, 2, 2) end
    end

    test "gpu_matrix_multiply rejects non-integer m" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_matrix_multiply([1.0], [1.0], "2", 2, 2) end
    end

    test "gpu_reduce_sum rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_reduce_sum("not") end
    end

    test "gpu_batch_z_score rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_batch_z_score("not", 2, 3) end
    end

    test "gpu_batch_z_score rejects non-integer n_rows" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_batch_z_score([1.0], "2", 3) end
    end

    test "gpu_batch_z_score rejects non-integer n_cols" do
      assert_raise FunctionClauseError, fn -> Compute.gpu_batch_z_score([1.0], 2, "3") end
    end
  end
end

defmodule Cyanea.NativeTest do
  use ExUnit.Case, async: false

  alias Cyanea.Native

  @moduledoc """
  Tests for Cyanea.Native NIF stubs and bridge struct definitions.

  Since NIFs are compiled with `skip_compilation?: true` in dev/test,
  all NIF calls raise `ErlangError` with `:nif_not_loaded`. These tests
  verify function signatures (arity) and struct definitions.
  """

  # Helper: assert a NIF stub raises because NIFs aren't loaded.
  # When the .so is absent, on_load fails and the module becomes unavailable,
  # so calls raise UndefinedFunctionError. When the .so exists but a specific
  # NIF isn't bound, calls raise ErlangError with :nif_not_loaded.
  defp assert_nif_not_loaded(fun) do
    try do
      fun.()
      flunk("expected NIF call to raise, but it returned normally")
    rescue
      ErlangError -> :ok
      UndefinedFunctionError -> :ok
    end
  end

  # ===========================================================================
  # cyanea-core — Hashing & Compression
  # ===========================================================================

  describe "sha256/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.sha256("hello") end)
    end
  end

  describe "sha256_file/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.sha256_file("/tmp/test.txt") end)
    end
  end

  describe "zstd_compress/2" do
    test "raises nif_not_loaded with default level" do
      assert_nif_not_loaded(fn -> Native.zstd_compress("hello") end)
    end

    test "raises nif_not_loaded with explicit level" do
      assert_nif_not_loaded(fn -> Native.zstd_compress("hello", 5) end)
    end
  end

  describe "zstd_decompress/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.zstd_decompress(<<0, 1, 2>>) end)
    end
  end

  describe "gzip_compress/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.gzip_compress("hello", 6) end)
    end
  end

  describe "gzip_decompress/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.gzip_decompress(<<0, 1, 2>>) end)
    end
  end

  # ===========================================================================
  # cyanea-seq — Sequence I/O
  # ===========================================================================

  describe "fasta_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.fasta_stats("/tmp/test.fasta") end)
    end
  end

  describe "validate_dna/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.validate_dna("ATCG") end)
    end
  end

  describe "validate_rna/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.validate_rna("AUCG") end)
    end
  end

  describe "validate_protein/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.validate_protein("MVLK") end)
    end
  end

  describe "dna_reverse_complement/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.dna_reverse_complement("ATCG") end)
    end
  end

  describe "dna_transcribe/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.dna_transcribe("ATCG") end)
    end
  end

  describe "dna_gc_content/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.dna_gc_content("GCGC") end)
    end
  end

  describe "rna_translate/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.rna_translate("AUGCGA") end)
    end
  end

  describe "sequence_kmers/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.sequence_kmers("ATCGATCG", 3) end)
    end
  end

  describe "parse_fastq/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_fastq("/tmp/test.fastq") end)
    end
  end

  describe "fastq_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.fastq_stats("/tmp/test.fastq") end)
    end
  end

  describe "protein_molecular_weight/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.protein_molecular_weight("MVLK") end)
    end
  end

  # --- cyanea-seq new functions -----------------------------------------------

  describe "horspool_search/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.horspool_search("ATCGATCG", "ATC") end)
    end
  end

  describe "myers_search/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.myers_search("ATCGATCG", "ATC", 1) end)
    end
  end

  describe "fm_index_build/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.fm_index_build("ATCGATCG") end)
    end
  end

  describe "fm_index_count/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.fm_index_count(<<0, 1, 2>>, "ATC") end)
    end
  end

  describe "find_orfs/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.find_orfs("ATGATCGATCGTAA", 3) end)
    end
  end

  describe "minhash_sketch/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.minhash_sketch("ATCGATCG", 3, 100) end)
    end
  end

  # ===========================================================================
  # cyanea-io — File Format Parsing
  # ===========================================================================

  describe "csv_info/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.csv_info("/tmp/test.csv") end)
    end
  end

  describe "csv_preview/2" do
    test "raises nif_not_loaded with default limit" do
      assert_nif_not_loaded(fn -> Native.csv_preview("/tmp/test.csv") end)
    end

    test "raises nif_not_loaded with explicit limit" do
      assert_nif_not_loaded(fn -> Native.csv_preview("/tmp/test.csv", 50) end)
    end
  end

  describe "vcf_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.vcf_stats("/tmp/test.vcf") end)
    end
  end

  describe "bed_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.bed_stats("/tmp/test.bed") end)
    end
  end

  describe "gff3_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.gff3_stats("/tmp/test.gff3") end)
    end
  end

  # --- cyanea-io new functions ------------------------------------------------

  describe "parse_vcf/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_vcf("/tmp/test.vcf") end)
    end
  end

  describe "parse_bed/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_bed("/tmp/test.bed") end)
    end
  end

  describe "parse_gff3/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_gff3("/tmp/test.gff3") end)
    end
  end

  describe "sam_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.sam_stats("/tmp/test.sam") end)
    end
  end

  describe "bam_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.bam_stats("/tmp/test.bam") end)
    end
  end

  describe "parse_sam/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_sam("/tmp/test.sam") end)
    end
  end

  describe "parse_bam/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_bam("/tmp/test.bam") end)
    end
  end

  describe "parse_bed_intervals/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_bed_intervals("/tmp/test.bed") end)
    end
  end

  # ===========================================================================
  # cyanea-align — Sequence Alignment
  # ===========================================================================

  describe "align_dna/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.align_dna("ATCG", "ATCG", "local") end)
    end
  end

  describe "align_dna_custom/7" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.align_dna_custom("ATCG", "ATCG", "global", 2, -1, -5, -2)
      end)
    end
  end

  describe "align_protein/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.align_protein("MVLK", "MVLK", "global", "blosum62")
      end)
    end
  end

  describe "align_batch_dna/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.align_batch_dna([{"AT", "AT"}, {"GC", "GC"}], "local")
      end)
    end
  end

  describe "progressive_msa/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.progressive_msa(["ATCG", "ATCG", "ATCG"], "dna")
      end)
    end
  end

  # --- cyanea-align new functions ---------------------------------------------

  describe "banded_align_dna/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.banded_align_dna("ATCGATCG", "ATCGATCG", "global", 10)
      end)
    end
  end

  describe "banded_score_only/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.banded_score_only("ATCGATCG", "ATCGATCG", "global", 10)
      end)
    end
  end

  describe "poa_consensus/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.poa_consensus(["ATCGATCG", "ATCAATCG", "ATCGATCG"])
      end)
    end
  end

  # ===========================================================================
  # cyanea-stats — Statistical Methods
  # ===========================================================================

  describe "descriptive_stats/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.descriptive_stats([1.0, 2.0, 3.0]) end)
    end
  end

  describe "pearson_correlation/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pearson_correlation([1.0, 2.0], [3.0, 4.0]) end)
    end
  end

  describe "spearman_correlation/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.spearman_correlation([1.0, 2.0], [3.0, 4.0]) end)
    end
  end

  describe "t_test_one_sample/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.t_test_one_sample([1.0, 2.0, 3.0], 0.0) end)
    end
  end

  describe "t_test_two_sample/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.t_test_two_sample([1.0, 2.0], [3.0, 4.0], false) end)
    end
  end

  describe "mann_whitney_u/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.mann_whitney_u([1.0, 2.0], [3.0, 4.0]) end)
    end
  end

  describe "p_adjust_bonferroni/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.p_adjust_bonferroni([0.01, 0.05]) end)
    end
  end

  describe "p_adjust_bh/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.p_adjust_bh([0.01, 0.05]) end)
    end
  end

  # --- cyanea-stats new functions ---------------------------------------------

  describe "cohens_d/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.cohens_d([1.0, 2.0, 3.0], [4.0, 5.0, 6.0]) end)
    end
  end

  describe "odds_ratio/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.odds_ratio(10, 20, 30, 40) end)
    end
  end

  describe "normal_cdf/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.normal_cdf(1.96, 0.0, 1.0) end)
    end
  end

  describe "normal_pdf/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.normal_pdf(0.0, 0.0, 1.0) end)
    end
  end

  describe "chi_squared_cdf/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.chi_squared_cdf(3.84, 1) end)
    end
  end

  describe "bayesian_beta_update/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.bayesian_beta_update(1.0, 1.0, 7, 10) end)
    end
  end

  # ===========================================================================
  # cyanea-omics — Omics Data Structures
  # ===========================================================================

  describe "classify_variant/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.classify_variant("chr1", 100, "A", ["G"]) end)
    end
  end

  describe "merge_genomic_intervals/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.merge_genomic_intervals(["chr1"], [0], [100])
      end)
    end
  end

  describe "genomic_coverage/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.genomic_coverage(["chr1"], [0], [100], "chr1")
      end)
    end
  end

  describe "expression_summary/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.expression_summary([[1.0]], ["gene1"], ["s1"])
      end)
    end
  end

  describe "log_transform_matrix/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.log_transform_matrix([[1.0, 2.0]], 1.0) end)
    end
  end

  # ===========================================================================
  # cyanea-ml — ML Primitives
  # ===========================================================================

  describe "kmeans/5" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.kmeans([0.0, 0.0, 1.0, 1.0], 2, 2, 100, 42)
      end)
    end
  end

  describe "dbscan/5" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.dbscan([0.0, 0.0, 1.0, 1.0], 2, 0.5, 2, "euclidean")
      end)
    end
  end

  describe "pca/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.pca([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 3, 2)
      end)
    end
  end

  describe "tsne/5" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.tsne([1.0, 2.0, 3.0, 4.0], 2, 2, 5.0, 100)
      end)
    end
  end

  describe "umap/8" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.umap([1.0, 2.0, 3.0, 4.0], 2, 2, 15, 0.1, 200, "euclidean", 42)
      end)
    end
  end

  describe "kmer_embedding/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.kmer_embedding("ATCGATCG", 3, "dna")
      end)
    end
  end

  describe "batch_embed/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.batch_embed(["ATCG", "GCTA"], 3, "dna")
      end)
    end
  end

  describe "pairwise_distances/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.pairwise_distances([0.0, 0.0, 1.0, 1.0], 2, "euclidean")
      end)
    end
  end

  # --- cyanea-ml new functions ------------------------------------------------

  describe "hierarchical_cluster/5" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.hierarchical_cluster([0.0, 0.0, 1.0, 1.0, 2.0, 2.0], 2, 2, "average", "euclidean")
      end)
    end
  end

  describe "knn_classify/6" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.knn_classify(
          [0.0, 0.0, 1.0, 1.0], 2, 1, "euclidean", [0, 1], [0.5, 0.5]
        )
      end)
    end
  end

  describe "linear_regression_fit/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.linear_regression_fit([1.0, 2.0, 3.0, 4.0], 2, [1.0, 2.0])
      end)
    end
  end

  describe "linear_regression_predict/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.linear_regression_predict([0.5, 0.3], 0.1, [1.0, 2.0], 2)
      end)
    end
  end

  describe "random_forest_fit/6" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.random_forest_fit(
          [1.0, 2.0, 3.0, 4.0], 2, [0, 1], 10, 5, 42
        )
      end)
    end
  end

  describe "random_forest_predict/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.random_forest_predict(<<0, 1, 2>>, [1.0, 2.0], 2)
      end)
    end
  end

  describe "hmm_viterbi/6" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.hmm_viterbi(
          2, 2,
          [0.5, 0.5],
          [0.7, 0.3, 0.4, 0.6],
          [0.9, 0.1, 0.2, 0.8],
          [0, 1, 0]
        )
      end)
    end
  end

  describe "hmm_forward/6" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.hmm_forward(
          2, 2,
          [0.5, 0.5],
          [0.7, 0.3, 0.4, 0.6],
          [0.9, 0.1, 0.2, 0.8],
          [0, 1, 0]
        )
      end)
    end
  end

  describe "normalize_min_max/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.normalize_min_max([1.0, 2.0, 3.0]) end)
    end
  end

  describe "normalize_z_score/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.normalize_z_score([1.0, 2.0, 3.0]) end)
    end
  end

  describe "silhouette_score/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.silhouette_score(
          [0.0, 0.0, 1.0, 1.0, 5.0, 5.0], 2, [0, 0, 1], "euclidean"
        )
      end)
    end
  end

  describe "minhash_jaccard/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.minhash_jaccard([1, 2, 3, 4], [2, 3, 4, 5])
      end)
    end
  end

  # ===========================================================================
  # cyanea-chem — Chemistry / Small Molecules
  # ===========================================================================

  describe "smiles_properties/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.smiles_properties("CCO") end)
    end
  end

  describe "smiles_fingerprint/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.smiles_fingerprint("CCO", 2, 1024) end)
    end
  end

  describe "tanimoto/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.tanimoto("CCO", "CC", 2, 1024) end)
    end
  end

  describe "smiles_substructure/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.smiles_substructure("c1ccccc1O", "c1ccccc1") end)
    end
  end

  # --- cyanea-chem new functions ----------------------------------------------

  describe "canonical_smiles/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.canonical_smiles("C(C)O") end)
    end
  end

  describe "parse_sdf_file/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.parse_sdf_file("/tmp/test.sdf") end)
    end
  end

  describe "maccs_fingerprint/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.maccs_fingerprint("CCO") end)
    end
  end

  # ===========================================================================
  # cyanea-struct — 3D Structures
  # ===========================================================================

  @sample_pdb """
  HEADER    TEST
  ATOM      1  N   ALA A   1       1.000   2.000   3.000  1.00  0.00           N
  ATOM      2  CA  ALA A   1       2.000   3.000   4.000  1.00  0.00           C
  END
  """

  @sample_mmcif """
  data_test
  _entry.id TEST
  loop_
  _atom_site.id
  _atom_site.label_atom_id
  _atom_site.label_comp_id
  _atom_site.label_asym_id
  _atom_site.label_seq_id
  _atom_site.Cartn_x
  _atom_site.Cartn_y
  _atom_site.Cartn_z
  1 CA ALA A 1 1.0 2.0 3.0
  """

  describe "pdb_info/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_info(@sample_pdb) end)
    end
  end

  describe "pdb_file_info/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_file_info("/tmp/test.pdb") end)
    end
  end

  describe "pdb_secondary_structure/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_secondary_structure(@sample_pdb, "A") end)
    end
  end

  describe "pdb_rmsd/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_rmsd(@sample_pdb, @sample_pdb, "A", "A") end)
    end
  end

  # --- cyanea-struct new functions --------------------------------------------

  describe "mmcif_info/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.mmcif_info(@sample_mmcif) end)
    end
  end

  describe "pdb_contact_map/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_contact_map(@sample_pdb, "A", 8.0) end)
    end
  end

  describe "pdb_kabsch/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.pdb_kabsch(@sample_pdb, @sample_pdb, "A", "A")
      end)
    end
  end

  describe "pdb_ramachandran/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_ramachandran(@sample_pdb) end)
    end
  end

  describe "pdb_bfactor_analysis/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.pdb_bfactor_analysis(@sample_pdb) end)
    end
  end

  describe "mmcif_file_info/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.mmcif_file_info("/tmp/test.cif") end)
    end
  end

  # ===========================================================================
  # cyanea-phylo — Phylogenetics
  # ===========================================================================

  describe "newick_info/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.newick_info("((A:0.1,B:0.2):0.3,C:0.4);") end)
    end
  end

  describe "newick_robinson_foulds/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.newick_robinson_foulds("((A,B),C);", "((A,C),B);")
      end)
    end
  end

  describe "evolutionary_distance/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.evolutionary_distance("ATCGATCG", "ATCAATCG", "p")
      end)
    end
  end

  describe "build_upgma/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.build_upgma(["ATCG", "ATCG", "ATCG"], ["A", "B", "C"], "p")
      end)
    end
  end

  describe "build_nj/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.build_nj(["ATCG", "ATCG", "ATCG"], ["A", "B", "C"], "jc")
      end)
    end
  end

  # --- cyanea-phylo new functions ---------------------------------------------

  describe "nexus_parse/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.nexus_parse("#NEXUS\nBEGIN TAXA;\nDIMENSIONS NTAX=2;\nTAXLABELS A B;\nEND;")
      end)
    end
  end

  describe "nexus_write/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.nexus_write(["A", "B"], ["((A,B));"])
      end)
    end
  end

  describe "robinson_foulds_normalized/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.robinson_foulds_normalized("((A,B),C);", "((A,C),B);")
      end)
    end
  end

  describe "bootstrap_support/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.bootstrap_support(["ATCG", "ATCA"], "((A,B));", 10, "p")
      end)
    end
  end

  describe "ancestral_reconstruction/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.ancestral_reconstruction("((A,B),C);", ["A", "G", "A"])
      end)
    end
  end

  describe "branch_score_distance/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.branch_score_distance("((A:0.1,B:0.2):0.3,C:0.4);", "((A:0.2,B:0.1):0.3,C:0.4);")
      end)
    end
  end

  # ===========================================================================
  # cyanea-gpu — GPU Compute
  # ===========================================================================

  describe "gpu_info/0" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.gpu_info() end)
    end
  end

  # --- cyanea-gpu new functions -----------------------------------------------

  describe "gpu_pairwise_distances/4" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.gpu_pairwise_distances([0.0, 0.0, 1.0, 1.0], 2, 2, "euclidean")
      end)
    end
  end

  describe "gpu_matrix_multiply/5" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.gpu_matrix_multiply(
          [1.0, 2.0, 3.0, 4.0],
          [5.0, 6.0, 7.0, 8.0],
          2, 2, 2
        )
      end)
    end
  end

  describe "gpu_reduce_sum/1" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.gpu_reduce_sum([1.0, 2.0, 3.0]) end)
    end
  end

  describe "gpu_batch_z_score/3" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.gpu_batch_z_score([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], 2, 3)
      end)
    end
  end

  # ===========================================================================
  # Bridge struct definitions
  # ===========================================================================

  describe "bridge structs — existing" do
    test "FastaStats has correct fields" do
      assert_struct_fields(Native.FastaStats, [
        :sequence_count, :total_bases, :gc_content, :avg_length
      ])
    end

    test "CsvInfo has correct fields" do
      assert_struct_fields(Native.CsvInfo, [
        :row_count, :column_count, :columns, :has_headers
      ])
    end

    test "FastqRecord has correct fields" do
      assert_struct_fields(Native.FastqRecord, [
        :name, :description, :sequence, :quality
      ])
    end

    test "FastqStats has correct fields" do
      assert_struct_fields(Native.FastqStats, [
        :sequence_count, :total_bases, :gc_content, :avg_length,
        :mean_quality, :q20_fraction, :q30_fraction
      ])
    end

    test "AlignmentResult has correct fields" do
      assert_struct_fields(Native.AlignmentResult, [
        :score, :aligned_query, :aligned_target,
        :query_start, :query_end, :target_start, :target_end,
        :cigar, :identity, :num_matches, :num_mismatches,
        :num_gaps, :alignment_length
      ])
    end

    test "MsaResult has correct fields" do
      assert_struct_fields(Native.MsaResult, [:aligned, :n_sequences, :n_columns, :conservation])
    end

    test "DescriptiveStats has correct fields" do
      assert_struct_fields(Native.DescriptiveStats, [
        :count, :mean, :median, :variance, :sample_variance,
        :std_dev, :sample_std_dev, :min, :max, :range,
        :q1, :q3, :iqr, :skewness, :kurtosis
      ])
    end

    test "TestResult has correct fields" do
      assert_struct_fields(Native.TestResult, [
        :statistic, :p_value, :degrees_of_freedom, :method
      ])
    end

    test "VariantClassification has correct fields" do
      assert_struct_fields(Native.VariantClassification, [
        :chrom, :position, :variant_type,
        :is_snv, :is_indel, :is_transition, :is_transversion
      ])
    end

    test "GenomicInterval has correct fields" do
      assert_struct_fields(Native.GenomicInterval, [
        :chrom, :start, :end, :strand
      ])
    end

    test "ExpressionSummary has correct fields" do
      assert_struct_fields(Native.ExpressionSummary, [
        :n_features, :n_samples, :feature_names, :sample_names,
        :feature_means, :sample_means
      ])
    end

    test "VcfStats has correct fields" do
      assert_struct_fields(Native.VcfStats, [
        :variant_count, :snv_count, :indel_count, :pass_count, :chromosomes
      ])
    end

    test "BedStats has correct fields" do
      assert_struct_fields(Native.BedStats, [:record_count, :total_bases, :chromosomes])
    end

    test "GffStats has correct fields" do
      assert_struct_fields(Native.GffStats, [
        :gene_count, :transcript_count, :exon_count, :protein_coding_count, :chromosomes
      ])
    end

    test "KMeansResult has correct fields" do
      assert_struct_fields(Native.KMeansResult, [
        :labels, :centroids, :n_features, :inertia, :n_iter
      ])
    end

    test "DbscanResult has correct fields" do
      assert_struct_fields(Native.DbscanResult, [:labels, :n_clusters])
    end

    test "PcaResult has correct fields" do
      assert_struct_fields(Native.PcaResult, [
        :transformed, :explained_variance, :explained_variance_ratio,
        :components, :n_components, :n_features
      ])
    end

    test "TsneResult has correct fields" do
      assert_struct_fields(Native.TsneResult, [
        :embedding, :n_samples, :n_components, :kl_divergence
      ])
    end

    test "UmapResult has correct fields" do
      assert_struct_fields(Native.UmapResult, [
        :embedding, :n_samples, :n_components, :n_epochs
      ])
    end

    test "MolecularProperties has correct fields" do
      assert_struct_fields(Native.MolecularProperties, [
        :formula, :weight, :exact_mass, :hbd, :hba,
        :rotatable_bonds, :ring_count, :aromatic_ring_count,
        :atom_count, :bond_count
      ])
    end

    test "PdbInfo has correct fields" do
      assert_struct_fields(Native.PdbInfo, [
        :id, :chain_count, :residue_count, :atom_count, :chains
      ])
    end

    test "SecondaryStructure has correct fields" do
      assert_struct_fields(Native.SecondaryStructure, [
        :assignments, :helix_fraction, :sheet_fraction, :coil_fraction
      ])
    end

    test "NewickInfo has correct fields" do
      assert_struct_fields(Native.NewickInfo, [:leaf_count, :leaf_names, :newick])
    end

    test "GpuInfo has correct fields" do
      assert_struct_fields(Native.GpuInfo, [:available, :backend])
    end
  end

  describe "bridge structs — new" do
    test "OrfResult has correct fields" do
      assert_struct_fields(Native.OrfResult, [
        :start, :end, :frame, :strand, :sequence
      ])
    end

    test "VcfRecord has correct fields" do
      assert_struct_fields(Native.VcfRecord, [
        :chrom, :position, :ref_allele, :alt_alleles, :quality, :filter
      ])
    end

    test "BedRecord has correct fields" do
      assert_struct_fields(Native.BedRecord, [
        :chrom, :start, :end, :name, :score, :strand
      ])
    end

    test "GffGene has correct fields" do
      assert_struct_fields(Native.GffGene, [
        :id, :symbol, :chrom, :start, :end, :strand, :gene_type, :transcript_count
      ])
    end

    test "SamRecord has correct fields" do
      assert_struct_fields(Native.SamRecord, [
        :qname, :flag, :rname, :pos, :mapq, :cigar, :sequence, :quality
      ])
    end

    test "SamStats has correct fields" do
      assert_struct_fields(Native.SamStats, [
        :total_reads, :mapped, :unmapped, :avg_mapq, :avg_length
      ])
    end

    test "SdfMolecule has correct fields" do
      assert_struct_fields(Native.SdfMolecule, [
        :name, :atom_count, :bond_count, :formula, :weight
      ])
    end

    test "HierarchicalResult has correct fields" do
      assert_struct_fields(Native.HierarchicalResult, [
        :labels, :merge_distances
      ])
    end

    test "LinearRegressionResult has correct fields" do
      assert_struct_fields(Native.LinearRegressionResult, [
        :weights, :bias, :r_squared
      ])
    end

    test "ContactMapResult has correct fields" do
      assert_struct_fields(Native.ContactMapResult, [
        :contacts, :n_residues, :contact_density
      ])
    end

    test "SuperpositionResult has correct fields" do
      assert_struct_fields(Native.SuperpositionResult, [
        :rmsd, :rotation, :translation
      ])
    end

    test "RamachandranEntry has correct fields" do
      assert_struct_fields(Native.RamachandranEntry, [
        :residue_num, :residue_name, :phi, :psi, :region
      ])
    end

    test "BfactorResult has correct fields" do
      assert_struct_fields(Native.BfactorResult, [
        :mean, :std_dev, :min, :max, :per_chain
      ])
    end

    test "NexusFile has correct fields" do
      assert_struct_fields(Native.NexusFile, [
        :taxa, :tree_names, :tree_newicks
      ])
    end
  end

  describe "bridge struct instantiation" do
    test "new structs can be instantiated with default nil values" do
      assert %Native.OrfResult{} = %Native.OrfResult{}
      assert %Native.VcfRecord{} = %Native.VcfRecord{}
      assert %Native.BedRecord{} = %Native.BedRecord{}
      assert %Native.GffGene{} = %Native.GffGene{}
      assert %Native.SamRecord{} = %Native.SamRecord{}
      assert %Native.SamStats{} = %Native.SamStats{}
      assert %Native.SdfMolecule{} = %Native.SdfMolecule{}
      assert %Native.HierarchicalResult{} = %Native.HierarchicalResult{}
      assert %Native.LinearRegressionResult{} = %Native.LinearRegressionResult{}
      assert %Native.ContactMapResult{} = %Native.ContactMapResult{}
      assert %Native.SuperpositionResult{} = %Native.SuperpositionResult{}
      assert %Native.RamachandranEntry{} = %Native.RamachandranEntry{}
      assert %Native.BfactorResult{} = %Native.BfactorResult{}
      assert %Native.NexusFile{} = %Native.NexusFile{}
    end

    test "new structs can be instantiated with values" do
      orf = %Native.OrfResult{start: 0, end: 99, frame: 0, strand: "+", sequence: "ATG"}
      assert orf.start == 0
      assert orf.end == 99
      assert orf.frame == 0
      assert orf.strand == "+"
      assert orf.sequence == "ATG"

      vcf = %Native.VcfRecord{chrom: "chr1", position: 100, ref_allele: "A", alt_alleles: ["G"], quality: 30.0, filter: "PASS"}
      assert vcf.chrom == "chr1"
      assert vcf.position == 100

      sam = %Native.SamStats{total_reads: 1000, mapped: 950, unmapped: 50, avg_mapq: 30.0, avg_length: 150.0}
      assert sam.total_reads == 1000
      assert sam.mapped == 950

      nexus = %Native.NexusFile{taxa: ["A", "B"], tree_names: ["tree1"], tree_newicks: ["((A,B));"]}
      assert nexus.taxa == ["A", "B"]
      assert length(nexus.tree_newicks) == 1
    end
  end

  # ===========================================================================
  # Helper
  # ===========================================================================

  defp assert_struct_fields(module, expected_fields) do
    s = struct(module)
    for field <- expected_fields do
      assert Map.has_key?(s, field),
        "expected #{inspect(module)} to have field #{inspect(field)}"
    end
  end
end

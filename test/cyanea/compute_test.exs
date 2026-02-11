defmodule Cyanea.ComputeTest do
  use ExUnit.Case, async: true

  alias Cyanea.Compute

  @moduledoc """
  Tests for the Compute context.

  Since NIFs are compiled with `skip_compilation?: true` in dev/test,
  all NIF calls will return `{:error, :nif_not_loaded}`. These tests
  verify the wrapper's error handling and function signatures.
  """

  # ===========================================================================
  # Sequence validation
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

    test "csv_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.csv_info("/tmp/test.csv")
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

    test "align_protein returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.align_protein("MVLK", "MVLK")
    end

    test "align_batch_dna returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.align_batch_dna([{"AT", "AT"}])
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

    test "t_test_two_sample returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.t_test_two_sample([1.0, 2.0], [3.0, 4.0])
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

    test "expression_summary returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.expression_summary([[1.0]], ["gene1"], ["s1"])
    end
  end

  # ===========================================================================
  # Compression
  # ===========================================================================

  describe "compression functions" do
    test "zstd_compress returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.zstd_compress("hello")
    end

    test "zstd_decompress returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.zstd_decompress(<<0, 1, 2>>)
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

  # ===========================================================================
  # MSA
  # ===========================================================================

  describe "progressive_msa" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.progressive_msa(["ATCG", "ATCG"])
    end

    test "accepts mode parameter" do
      assert {:error, :nif_not_loaded} = Compute.progressive_msa(["MVLK", "MVLK"], "protein")
    end
  end

  # ===========================================================================
  # ML
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
  end

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
  end

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

    test "pairwise_distances returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.pairwise_distances([0.0, 0.0, 1.0, 1.0], 2)
    end

    test "pairwise_distances accepts metric parameter" do
      assert {:error, :nif_not_loaded} = Compute.pairwise_distances([0.0, 0.0], 2, "manhattan")
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

  # ===========================================================================
  # Structures
  # ===========================================================================

  describe "structure functions" do
    @sample_pdb "HEADER    TEST\nATOM      1  CA  ALA A   1       1.0   2.0   3.0  1.00  0.00           C\nEND\n"

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

  # ===========================================================================
  # GPU
  # ===========================================================================

  describe "gpu functions" do
    test "gpu_info returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Compute.gpu_info()
    end
  end

  # ===========================================================================
  # Guard clauses
  # ===========================================================================

  describe "guard clauses" do
    test "validate_dna rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.validate_dna(123) end
    end

    test "descriptive_stats rejects non-list" do
      assert_raise FunctionClauseError, fn -> Compute.descriptive_stats("not a list") end
    end

    test "sequence_kmers rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Compute.sequence_kmers("ATCG", "3") end
    end

    test "kmeans rejects non-list data" do
      assert_raise FunctionClauseError, fn -> Compute.kmeans("not a list", 2, 2) end
    end

    test "kmeans rejects non-integer n_features" do
      assert_raise FunctionClauseError, fn -> Compute.kmeans([1.0], "2", 2) end
    end

    test "pca rejects non-integer n_components" do
      assert_raise FunctionClauseError, fn -> Compute.pca([1.0], 1, "2") end
    end

    test "smiles_properties rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.smiles_properties(123) end
    end

    test "pdb_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.pdb_info(123) end
    end

    test "newick_info rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Compute.newick_info(123) end
    end

    test "build_upgma rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Compute.build_upgma("ATCG", ["A"], "p") end
    end

    test "kmer_embedding rejects non-binary sequence" do
      assert_raise FunctionClauseError, fn -> Compute.kmer_embedding(123, 3) end
    end

    test "dbscan rejects non-number eps" do
      assert_raise FunctionClauseError, fn -> Compute.dbscan([1.0], 1, "bad", 2) end
    end
  end
end

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
  end
end

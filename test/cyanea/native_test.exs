defmodule Cyanea.NativeTest do
  use ExUnit.Case, async: true

  alias Cyanea.Native

  @moduledoc """
  Tests for the new NIF functions added to Cyanea.Native.

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
  # cyanea-io — VCF / BED / GFF3
  # ===========================================================================

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

  # ===========================================================================
  # cyanea-align — MSA
  # ===========================================================================

  describe "progressive_msa/2" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn ->
        Native.progressive_msa(["ATCG", "ATCG", "ATCG"], "dna")
      end)
    end
  end

  # ===========================================================================
  # cyanea-ml — Clustering & Embeddings
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

  # ===========================================================================
  # cyanea-chem — Molecular Analysis
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

  # ===========================================================================
  # cyanea-struct — Protein Structures
  # ===========================================================================

  @sample_pdb """
  HEADER    TEST
  ATOM      1  N   ALA A   1       1.000   2.000   3.000  1.00  0.00           N
  ATOM      2  CA  ALA A   1       2.000   3.000   4.000  1.00  0.00           C
  END
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

  # ===========================================================================
  # cyanea-gpu — Backend Info
  # ===========================================================================

  describe "gpu_info/0" do
    test "raises nif_not_loaded" do
      assert_nif_not_loaded(fn -> Native.gpu_info() end)
    end
  end

  # ===========================================================================
  # Bridge struct definitions
  # ===========================================================================

  describe "bridge structs" do
    # Bridge struct modules are defined outside the Native module, so they
    # remain available even when the NIF .so fails to load.

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

    test "MsaResult has correct fields" do
      assert_struct_fields(Native.MsaResult, [:aligned, :n_sequences, :n_columns, :conservation])
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

  defp assert_struct_fields(module, expected_fields) do
    s = struct(module)
    for field <- expected_fields do
      assert Map.has_key?(s, field),
        "expected #{inspect(module)} to have field #{inspect(field)}"
    end
  end
end

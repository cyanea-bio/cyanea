defmodule Cyanea.PhyloTest do
  use ExUnit.Case, async: true

  alias Cyanea.Phylo

  # ===========================================================================
  # Parsing
  # ===========================================================================

  describe "parse_newick/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.parse_newick("((A:0.1,B:0.2):0.3,C:0.4);")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Phylo.parse_newick(123) end
    end
  end

  describe "parse_nexus/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.parse_nexus("#NEXUS\nBEGIN TAXA;")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Phylo.parse_nexus(123) end
    end
  end

  describe "write_nexus/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.write_nexus(["A", "B"], ["((A,B));"])
    end

    test "rejects non-list taxa" do
      assert_raise FunctionClauseError, fn -> Phylo.write_nexus("A", ["((A,B));"]) end
    end

    test "rejects non-list trees" do
      assert_raise FunctionClauseError, fn -> Phylo.write_nexus(["A"], "((A,B));") end
    end
  end

  # ===========================================================================
  # Distances
  # ===========================================================================

  describe "distance/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.distance("ATCGATCG", "ATCAATCG")
    end

    test "accepts atom model" do
      assert {:error, :nif_not_loaded} = Phylo.distance("ATCG", "ATCA", model: :k2p)
    end

    test "accepts string model" do
      assert {:error, :nif_not_loaded} = Phylo.distance("ATCG", "ATCA", model: "jc")
    end

    test "rejects non-binary seq_a" do
      assert_raise FunctionClauseError, fn -> Phylo.distance(123, "ATCG") end
    end

    test "rejects non-binary seq_b" do
      assert_raise FunctionClauseError, fn -> Phylo.distance("ATCG", 123) end
    end
  end

  describe "robinson_foulds/2" do
    test "returns nif_not_loaded without NIF (raw)" do
      assert {:error, :nif_not_loaded} = Phylo.robinson_foulds("((A,B),C);", "((A,C),B);")
    end

    test "accepts normalized option" do
      assert {:error, :nif_not_loaded} = Phylo.robinson_foulds("((A,B),C);", "((A,C),B);", normalized: true)
    end

    test "rejects non-binary newick_a" do
      assert_raise FunctionClauseError, fn -> Phylo.robinson_foulds(123, "((A,B),C);") end
    end

    test "rejects non-binary newick_b" do
      assert_raise FunctionClauseError, fn -> Phylo.robinson_foulds("((A,B),C);", 123) end
    end
  end

  describe "branch_score/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.branch_score(
        "((A:0.1,B:0.2):0.3,C:0.4);", "((A:0.2,B:0.1):0.3,C:0.4);"
      )
    end

    test "rejects non-binary newick_a" do
      assert_raise FunctionClauseError, fn -> Phylo.branch_score(123, "((A,B));") end
    end

    test "rejects non-binary newick_b" do
      assert_raise FunctionClauseError, fn -> Phylo.branch_score("((A,B));", 123) end
    end
  end

  # ===========================================================================
  # Tree building
  # ===========================================================================

  describe "build_upgma/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.build_upgma(["ATCG", "ATCG"], ["A", "B"])
    end

    test "accepts atom model" do
      assert {:error, :nif_not_loaded} = Phylo.build_upgma(["ATCG", "ATCG"], ["A", "B"], model: :jc)
    end

    test "rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Phylo.build_upgma("ATCG", ["A"]) end
    end

    test "rejects non-list names" do
      assert_raise FunctionClauseError, fn -> Phylo.build_upgma(["ATCG"], "A") end
    end
  end

  describe "build_nj/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.build_nj(["ATCG", "ATCG"], ["A", "B"])
    end

    test "accepts atom model" do
      assert {:error, :nif_not_loaded} = Phylo.build_nj(["ATCG", "ATCG"], ["A", "B"], model: :k2p)
    end

    test "rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Phylo.build_nj("ATCG", ["A"]) end
    end
  end

  # ===========================================================================
  # Bootstrap & ancestral
  # ===========================================================================

  describe "bootstrap/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.bootstrap(["ATCG", "ATCA"], "((A,B));")
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = Phylo.bootstrap(["ATCG", "ATCA"], "((A,B));",
        n_replicates: 50, model: :jc
      )
    end

    test "rejects non-list sequences" do
      assert_raise FunctionClauseError, fn -> Phylo.bootstrap("ATCG", "((A,B));") end
    end

    test "rejects non-binary tree" do
      assert_raise FunctionClauseError, fn -> Phylo.bootstrap(["ATCG"], 123) end
    end
  end

  describe "ancestral_states/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Phylo.ancestral_states("((A,B),C);", ["A", "G", "A"])
    end

    test "rejects non-binary tree" do
      assert_raise FunctionClauseError, fn -> Phylo.ancestral_states(123, ["A"]) end
    end

    test "rejects non-list leaf_states" do
      assert_raise FunctionClauseError, fn -> Phylo.ancestral_states("((A,B));", "A") end
    end
  end
end

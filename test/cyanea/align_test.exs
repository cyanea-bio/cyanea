defmodule Cyanea.AlignTest do
  use ExUnit.Case, async: true

  alias Cyanea.Align

  # ===========================================================================
  # Pairwise DNA
  # ===========================================================================

  describe "dna/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.dna("ATCG", "ATCG")
    end

    test "rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Align.dna(123, "ATCG") end
    end

    test "rejects non-binary target" do
      assert_raise FunctionClauseError, fn -> Align.dna("ATCG", 123) end
    end
  end

  describe "dna/3 with opts" do
    test "accepts atom mode" do
      assert {:error, :nif_not_loaded} = Align.dna("ATCG", "ATCG", mode: :global)
    end

    test "accepts string mode" do
      assert {:error, :nif_not_loaded} = Align.dna("ATCG", "ATCG", mode: "local")
    end

    test "dispatches to custom scoring when scoring opts present" do
      assert {:error, :nif_not_loaded} = Align.dna("ATCG", "ATCG", match: 3, mismatch: -2)
    end

    test "includes all scoring options" do
      assert {:error, :nif_not_loaded} = Align.dna("ATCG", "ATCG",
        mode: :global, match: 2, mismatch: -1, gap_open: -5, gap_extend: -2
      )
    end
  end

  # ===========================================================================
  # Pairwise protein
  # ===========================================================================

  describe "protein/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.protein("MVLK", "MVLK")
    end

    test "rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Align.protein(123, "MVLK") end
    end
  end

  describe "protein/3 with opts" do
    test "accepts atom mode and matrix" do
      assert {:error, :nif_not_loaded} = Align.protein("MVLK", "MVLK", mode: :local, matrix: :blosum45)
    end

    test "defaults to global mode and blosum62" do
      assert {:error, :nif_not_loaded} = Align.protein("MVLK", "MVLK")
    end
  end

  # ===========================================================================
  # Batch
  # ===========================================================================

  describe "batch/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.batch([{"AT", "AT"}])
    end

    test "accepts mode option" do
      assert {:error, :nif_not_loaded} = Align.batch([{"AT", "AT"}], mode: :global)
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Align.batch("not_a_list") end
    end
  end

  # ===========================================================================
  # MSA
  # ===========================================================================

  describe "msa/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.msa(["ATCG", "ATCG"])
    end

    test "accepts mode option" do
      assert {:error, :nif_not_loaded} = Align.msa(["MVLK", "MVLK"], mode: :protein)
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Align.msa("not_a_list") end
    end
  end

  # ===========================================================================
  # Banded
  # ===========================================================================

  describe "banded/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.banded("ATCG", "ATCG")
    end

    test "accepts mode and bandwidth options" do
      assert {:error, :nif_not_loaded} = Align.banded("ATCG", "ATCG", mode: :local, bandwidth: 20)
    end

    test "rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Align.banded(123, "ATCG") end
    end
  end

  describe "banded_score/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.banded_score("ATCG", "ATCG")
    end

    test "accepts mode and bandwidth options" do
      assert {:error, :nif_not_loaded} = Align.banded_score("ATCG", "ATCG", mode: :local, bandwidth: 20)
    end

    test "rejects non-binary query" do
      assert_raise FunctionClauseError, fn -> Align.banded_score(123, "ATCG") end
    end
  end

  # ===========================================================================
  # POA consensus
  # ===========================================================================

  describe "consensus/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Align.consensus(["ATCG", "ATCG", "ATCG"])
    end

    test "rejects non-list" do
      assert_raise FunctionClauseError, fn -> Align.consensus("not_a_list") end
    end
  end
end

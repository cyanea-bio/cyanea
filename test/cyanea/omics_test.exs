defmodule Cyanea.OmicsTest do
  use ExUnit.Case, async: false

  alias Cyanea.Omics

  describe "classify_variant/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Omics.classify_variant("chr1", 100, "A", ["G"])
    end
  end

  describe "merge_intervals/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Omics.merge_intervals(["chr1"], [0], [100])
    end

    test "rejects non-list chroms" do
      assert_raise FunctionClauseError, fn -> Omics.merge_intervals("chr1", [0], [100]) end
    end

    test "rejects non-list starts" do
      assert_raise FunctionClauseError, fn -> Omics.merge_intervals(["chr1"], 0, [100]) end
    end

    test "rejects non-list ends" do
      assert_raise FunctionClauseError, fn -> Omics.merge_intervals(["chr1"], [0], 100) end
    end
  end

  describe "coverage/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Omics.coverage(["chr1"], [0], [100], "chr1")
    end
  end

  describe "expression_summary/3" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Omics.expression_summary([[1.0]], ["gene1"], ["s1"])
    end
  end

  describe "log_transform/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Omics.log_transform([[1.0, 2.0]])
    end

    test "accepts pseudocount option" do
      assert {:error, :nif_not_loaded} = Omics.log_transform([[1.0, 2.0]], pseudocount: 0.5)
    end
  end
end

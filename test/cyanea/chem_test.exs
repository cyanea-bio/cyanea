defmodule Cyanea.ChemTest do
  use ExUnit.Case, async: false

  alias Cyanea.Chem

  describe "properties/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Chem.properties("CCO")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Chem.properties(123) end
    end
  end

  describe "canonical/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Chem.canonical("C(C)O")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Chem.canonical(123) end
    end
  end

  describe "fingerprint/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Chem.fingerprint("CCO")
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = Chem.fingerprint("CCO", radius: 3, bits: 1024)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Chem.fingerprint(123) end
    end
  end

  describe "maccs/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Chem.maccs("CCO")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Chem.maccs(123) end
    end
  end

  describe "tanimoto/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Chem.tanimoto("CCO", "CC")
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = Chem.tanimoto("CCO", "CC", radius: 3, bits: 1024)
    end

    test "rejects non-binary smiles_a" do
      assert_raise FunctionClauseError, fn -> Chem.tanimoto(123, "CC") end
    end

    test "rejects non-binary smiles_b" do
      assert_raise FunctionClauseError, fn -> Chem.tanimoto("CCO", 123) end
    end
  end

  describe "substructure?/2" do
    test "returns false when NIF not loaded" do
      assert Chem.substructure?("c1ccccc1O", "c1ccccc1") == false
    end

    test "rejects non-binary target" do
      assert_raise FunctionClauseError, fn -> Chem.substructure?(123, "c1ccccc1") end
    end

    test "rejects non-binary pattern" do
      assert_raise FunctionClauseError, fn -> Chem.substructure?("c1ccccc1O", 123) end
    end
  end

  describe "parse_sdf/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Chem.parse_sdf("/tmp/test.sdf")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Chem.parse_sdf(123) end
    end
  end
end

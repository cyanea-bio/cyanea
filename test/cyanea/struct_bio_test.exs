defmodule Cyanea.StructBioTest do
  use ExUnit.Case, async: false

  alias Cyanea.StructBio

  @sample_pdb "HEADER    TEST\nATOM      1  CA  ALA A   1       1.0   2.0   3.0  1.00  0.00           C\nEND\n"

  describe "parse_pdb/1" do
    test "parses PDB text" do
      assert {:error, :nif_not_loaded} = StructBio.parse_pdb(@sample_pdb)
    end

    test "detects file path by .pdb extension" do
      assert {:error, :nif_not_loaded} = StructBio.parse_pdb("/tmp/test.pdb")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> StructBio.parse_pdb(123) end
    end
  end

  describe "parse_mmcif/1" do
    test "parses mmCIF text" do
      assert {:error, :nif_not_loaded} = StructBio.parse_mmcif("data_test\n_entry.id TEST\n")
    end

    test "detects file path by .cif extension" do
      assert {:error, :nif_not_loaded} = StructBio.parse_mmcif("/tmp/test.cif")
    end

    test "detects file path by .mmcif extension" do
      assert {:error, :nif_not_loaded} = StructBio.parse_mmcif("/tmp/test.mmcif")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> StructBio.parse_mmcif(123) end
    end
  end

  describe "secondary_structure/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = StructBio.secondary_structure(@sample_pdb, "A")
    end

    test "rejects non-binary pdb_text" do
      assert_raise FunctionClauseError, fn -> StructBio.secondary_structure(123, "A") end
    end

    test "rejects non-binary chain_id" do
      assert_raise FunctionClauseError, fn -> StructBio.secondary_structure("pdb", 123) end
    end
  end

  describe "rmsd/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = StructBio.rmsd(@sample_pdb, @sample_pdb, "A", "A")
    end

    test "rejects non-binary pdb_a" do
      assert_raise FunctionClauseError, fn -> StructBio.rmsd(123, "pdb", "A", "A") end
    end
  end

  describe "kabsch/4" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = StructBio.kabsch(@sample_pdb, @sample_pdb, "A", "A")
    end

    test "rejects non-binary pdb_a" do
      assert_raise FunctionClauseError, fn -> StructBio.kabsch(123, "pdb", "A", "A") end
    end
  end

  describe "contact_map/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = StructBio.contact_map(@sample_pdb, "A")
    end

    test "accepts cutoff option" do
      assert {:error, :nif_not_loaded} = StructBio.contact_map(@sample_pdb, "A", cutoff: 10.0)
    end

    test "rejects non-binary pdb_text" do
      assert_raise FunctionClauseError, fn -> StructBio.contact_map(123, "A") end
    end

    test "rejects non-binary chain_id" do
      assert_raise FunctionClauseError, fn -> StructBio.contact_map("pdb", 123) end
    end
  end

  describe "ramachandran/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = StructBio.ramachandran(@sample_pdb)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> StructBio.ramachandran(123) end
    end
  end

  describe "bfactors/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = StructBio.bfactors(@sample_pdb)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> StructBio.bfactors(123) end
    end
  end
end

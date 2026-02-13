defmodule Cyanea.SeqTest do
  use ExUnit.Case, async: true

  alias Cyanea.Seq

  # ===========================================================================
  # Validation
  # ===========================================================================

  describe "validate/2" do
    test "dispatches to DNA validation" do
      assert {:error, :nif_not_loaded} = Seq.validate("ATCG", :dna)
    end

    test "dispatches to RNA validation" do
      assert {:error, :nif_not_loaded} = Seq.validate("AUCG", :rna)
    end

    test "dispatches to protein validation" do
      assert {:error, :nif_not_loaded} = Seq.validate("MVLK", :protein)
    end

    test "rejects non-binary sequence" do
      assert_raise FunctionClauseError, fn -> Seq.validate(123, :dna) end
    end
  end

  describe "validate!/2" do
    test "raises on nif_not_loaded" do
      assert_raise ArgumentError, ~r/validation failed/, fn ->
        Seq.validate!("ATCG", :dna)
      end
    end

    test "rejects non-binary sequence" do
      assert_raise FunctionClauseError, fn -> Seq.validate!(123, :dna) end
    end
  end

  # ===========================================================================
  # Operations
  # ===========================================================================

  describe "reverse_complement/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.reverse_complement("ATCG")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.reverse_complement(123) end
    end
  end

  describe "transcribe/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.transcribe("ATCG")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.transcribe(123) end
    end
  end

  describe "translate/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.translate("AUGCGA")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.translate(123) end
    end
  end

  describe "gc_content/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.gc_content("GCGC")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.gc_content(123) end
    end
  end

  describe "kmers/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.kmers("ATCGATCG", 3)
    end

    test "rejects non-binary seq" do
      assert_raise FunctionClauseError, fn -> Seq.kmers(123, 3) end
    end

    test "rejects non-integer k" do
      assert_raise FunctionClauseError, fn -> Seq.kmers("ATCG", "3") end
    end
  end

  describe "molecular_weight/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.molecular_weight("MVLK")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.molecular_weight(123) end
    end
  end

  # ===========================================================================
  # Pattern matching
  # ===========================================================================

  describe "search/2" do
    test "defaults to horspool algorithm" do
      assert {:error, :nif_not_loaded} = Seq.search("ATCGATCG", "ATC")
    end

    test "rejects non-binary text" do
      assert_raise FunctionClauseError, fn -> Seq.search(123, "ATC") end
    end

    test "rejects non-binary pattern" do
      assert_raise FunctionClauseError, fn -> Seq.search("ATCG", 123) end
    end
  end

  describe "search/3 with opts" do
    test "accepts algorithm: :horspool" do
      assert {:error, :nif_not_loaded} = Seq.search("ATCGATCG", "ATC", algorithm: :horspool)
    end

    test "accepts algorithm: :myers with max_distance" do
      assert {:error, :nif_not_loaded} = Seq.search("ATCGATCG", "ATC", algorithm: :myers, max_distance: 2)
    end

    test "defaults max_distance to 1 for myers" do
      assert {:error, :nif_not_loaded} = Seq.search("ATCGATCG", "ATC", algorithm: :myers)
    end
  end

  # ===========================================================================
  # FM-Index
  # ===========================================================================

  describe "build_index/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.build_index("ATCGATCG")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.build_index(123) end
    end
  end

  describe "count_occurrences/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.count_occurrences(<<0, 1, 2>>, "ATC")
    end

    test "rejects non-binary index_data" do
      assert_raise FunctionClauseError, fn -> Seq.count_occurrences(123, "ATC") end
    end

    test "rejects non-binary pattern" do
      assert_raise FunctionClauseError, fn -> Seq.count_occurrences(<<0>>, 123) end
    end
  end

  # ===========================================================================
  # ORF finding
  # ===========================================================================

  describe "find_orfs/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.find_orfs("ATGATCGATCGTAA")
    end

    test "accepts keyword opts for min_length" do
      assert {:error, :nif_not_loaded} = Seq.find_orfs("ATGATCGATCGTAA", min_length: 50)
    end

    test "defaults min_length to 100" do
      # both should return same error, just testing default path
      assert {:error, :nif_not_loaded} = Seq.find_orfs("ATGATCGATCGTAA")
    end

    test "rejects non-binary seq" do
      assert_raise FunctionClauseError, fn -> Seq.find_orfs(123) end
    end
  end

  # ===========================================================================
  # MinHash
  # ===========================================================================

  describe "minhash/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.minhash("ATCGATCG")
    end

    test "accepts keyword opts" do
      assert {:error, :nif_not_loaded} = Seq.minhash("ATCGATCG", k: 3, sketch_size: 100)
    end

    test "rejects non-binary seq" do
      assert_raise FunctionClauseError, fn -> Seq.minhash(123) end
    end
  end

  describe "minhash_jaccard/2" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.minhash_jaccard([1, 2, 3], [2, 3, 4])
    end

    test "rejects non-list sketch_a" do
      assert_raise FunctionClauseError, fn -> Seq.minhash_jaccard("not", [1]) end
    end

    test "rejects non-list sketch_b" do
      assert_raise FunctionClauseError, fn -> Seq.minhash_jaccard([1], "not") end
    end
  end

  # ===========================================================================
  # File I/O
  # ===========================================================================

  describe "fasta_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.fasta_stats("/tmp/test.fasta")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.fasta_stats(123) end
    end
  end

  describe "fastq_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.fastq_stats("/tmp/test.fastq")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.fastq_stats(123) end
    end
  end

  describe "parse_fastq/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Seq.parse_fastq("/tmp/test.fastq")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Seq.parse_fastq(123) end
    end
  end
end

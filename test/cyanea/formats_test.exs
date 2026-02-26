defmodule Cyanea.FormatsTest do
  use ExUnit.Case, async: false

  alias Cyanea.Formats

  # ===========================================================================
  # CSV
  # ===========================================================================

  describe "csv_info/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.csv_info("/tmp/test.csv")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.csv_info(123) end
    end
  end

  describe "csv_preview/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.csv_preview("/tmp/test.csv")
    end

    test "accepts limit option" do
      assert {:error, :nif_not_loaded} = Formats.csv_preview("/tmp/test.csv", limit: 50)
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.csv_preview(123) end
    end
  end

  # ===========================================================================
  # VCF
  # ===========================================================================

  describe "vcf_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.vcf_stats("/tmp/test.vcf")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.vcf_stats(123) end
    end
  end

  describe "parse_vcf/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.parse_vcf("/tmp/test.vcf")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.parse_vcf(123) end
    end
  end

  # ===========================================================================
  # BED
  # ===========================================================================

  describe "bed_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.bed_stats("/tmp/test.bed")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.bed_stats(123) end
    end
  end

  describe "parse_bed/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.parse_bed("/tmp/test.bed")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.parse_bed(123) end
    end
  end

  describe "parse_bed_intervals/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.parse_bed_intervals("/tmp/test.bed")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.parse_bed_intervals(123) end
    end
  end

  # ===========================================================================
  # GFF3
  # ===========================================================================

  describe "gff3_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.gff3_stats("/tmp/test.gff3")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.gff3_stats(123) end
    end
  end

  describe "parse_gff3/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.parse_gff3("/tmp/test.gff3")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.parse_gff3(123) end
    end
  end

  # ===========================================================================
  # SAM/BAM
  # ===========================================================================

  describe "sam_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.sam_stats("/tmp/test.sam")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.sam_stats(123) end
    end
  end

  describe "parse_sam/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.parse_sam("/tmp/test.sam")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.parse_sam(123) end
    end
  end

  describe "bam_stats/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.bam_stats("/tmp/test.bam")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.bam_stats(123) end
    end
  end

  describe "parse_bam/1" do
    test "returns nif_not_loaded without NIF" do
      assert {:error, :nif_not_loaded} = Formats.parse_bam("/tmp/test.bam")
    end

    test "rejects non-binary" do
      assert_raise FunctionClauseError, fn -> Formats.parse_bam(123) end
    end
  end
end

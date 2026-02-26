defmodule Cyanea.PreviewsTest do
  use Cyanea.DataCase

  alias Cyanea.Previews

  describe "preview_type/2" do
    test "detects FASTA files" do
      assert Previews.preview_type("seq.fasta") == :sequence
      assert Previews.preview_type("seq.fa") == :sequence
      assert Previews.preview_type("seq.fna") == :sequence
      assert Previews.preview_type("seq.faa") == :sequence
    end

    test "detects FASTQ files" do
      assert Previews.preview_type("reads.fastq") == :sequence
      assert Previews.preview_type("reads.fq") == :sequence
    end

    test "detects tabular files" do
      assert Previews.preview_type("data.csv") == :tabular
      assert Previews.preview_type("data.tsv") == :tabular
      assert Previews.preview_type("data.tab") == :tabular
    end

    test "detects variant files" do
      assert Previews.preview_type("variants.vcf") == :variant
    end

    test "detects interval files" do
      assert Previews.preview_type("regions.bed") == :interval
      assert Previews.preview_type("annotations.gff") == :interval
      assert Previews.preview_type("annotations.gff3") == :interval
      assert Previews.preview_type("annotations.gtf") == :interval
    end

    test "detects structure files" do
      assert Previews.preview_type("protein.pdb") == :structure
      assert Previews.preview_type("protein.ent") == :structure
    end

    test "detects image files" do
      assert Previews.preview_type("figure.png") == :image
      assert Previews.preview_type("photo.jpg") == :image
      assert Previews.preview_type("photo.jpeg") == :image
      assert Previews.preview_type("animation.gif") == :image
      assert Previews.preview_type("vector.svg") == :image
      assert Previews.preview_type("photo.webp") == :image
      assert Previews.preview_type("scan.tiff") == :image
    end

    test "detects PDF files" do
      assert Previews.preview_type("paper.pdf") == :pdf
    end

    test "detects markdown files" do
      assert Previews.preview_type("README.md") == :markdown
      assert Previews.preview_type("docs.markdown") == :markdown
    end

    test "detects text files by MIME type" do
      assert Previews.preview_type("unknown.txt", "text/plain") == :text
      assert Previews.preview_type("data.json", "application/json") == :text
    end

    test "returns unsupported for unknown types" do
      assert Previews.preview_type("binary.exe") == :unsupported
      assert Previews.preview_type("archive.zip") == :unsupported
    end

    test "is case insensitive on extensions" do
      assert Previews.preview_type("SEQ.FASTA") == :sequence
      assert Previews.preview_type("DATA.CSV") == :tabular
    end
  end

  describe "preview_data_for_sequence/1" do
    test "parses FASTA content" do
      content = """
      >seq1 test
      ATGCGATCGATCG
      >seq2 test
      GCTAGCTAGCTAG
      """

      result = Previews.preview_data_for_sequence(content)
      assert result["format"] == "fasta"
      assert result["sequence_count"] == 2
      assert result["total_length"] > 0
      assert is_float(result["gc_content"])
    end

    test "parses FASTQ content" do
      content = """
      @read1
      ATGCGATCG
      +
      IIIIIIIII
      @read2
      GCTAGCTAG
      +
      IIIIIIIII
      """

      result = Previews.preview_data_for_sequence(content)
      assert result["format"] == "fastq"
      assert result["sequence_count"] >= 1
    end
  end

  describe "preview_data_for_tabular/1" do
    test "parses CSV content" do
      content = """
      gene,expression,pvalue
      BRCA1,12.5,0.001
      TP53,8.3,0.05
      EGFR,15.7,0.003
      """

      result = Previews.preview_data_for_tabular(content)
      assert result["column_count"] == 3
      assert result["row_count"] == 3
      assert "gene" in result["columns"]
      assert length(result["preview_rows"]) == 3
    end

    test "parses TSV content" do
      content = "gene\texpression\nBRCA1\t12.5\nTP53\t8.3\n"

      result = Previews.preview_data_for_tabular(content)
      assert result["column_count"] == 2
      assert result["row_count"] == 2
    end

    test "handles empty content" do
      result = Previews.preview_data_for_tabular("")
      assert result["row_count"] == 0
      assert result["columns"] == []
    end
  end

  describe "preview_data_for_variant/1" do
    test "parses VCF content" do
      content = """
      ##fileformat=VCFv4.2
      #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSample1\tSample2
      chr1\t100\t.\tA\tT\t30\tPASS\tDP=50\tGT\t0/1\t0/0
      chr1\t200\t.\tG\tC\t25\tPASS\tDP=40\tGT\t0/0\t0/1
      """

      result = Previews.preview_data_for_variant(content)
      assert result["variant_count"] == 2
      assert result["sample_count"] == 2
      assert "Sample1" in result["samples"]
    end
  end

  describe "preview_data_for_interval/1" do
    test "parses BED content" do
      content = """
      chr1\t100\t200\tfeature1
      chr1\t300\t400\tfeature2
      chr2\t500\t600\tfeature3
      """

      result = Previews.preview_data_for_interval(content)
      assert result["format"] == "bed"
      assert result["region_count"] == 3
      assert is_map(result["chromosomes"])
    end

    test "parses GFF3 content" do
      content = """
      ##gff-version 3
      chr1\t.\tgene\t100\t200\t.\t+\t.\tID=gene1
      chr1\t.\texon\t100\t150\t.\t+\t.\tParent=gene1
      """

      result = Previews.preview_data_for_interval(content)
      assert result["format"] == "gff3"
      assert result["feature_count"] == 2
      assert is_map(result["feature_types"])
    end
  end

  describe "preview_data_for_markdown/1" do
    test "renders markdown to HTML" do
      content = "# Hello\n\nThis is **bold** text."

      result = Previews.preview_data_for_markdown(content)
      assert String.contains?(result["html"], "<h1>")
      assert String.contains?(result["html"], "<strong>")
      assert result["line_count"] > 0
    end
  end

  describe "preview_data_for_text/1" do
    test "returns lines with metadata" do
      content = "line1\nline2\nline3"

      result = Previews.preview_data_for_text(content)
      assert result["line_count"] == 3
      assert length(result["preview_lines"]) == 3
      assert result["truncated"] == false
    end
  end
end

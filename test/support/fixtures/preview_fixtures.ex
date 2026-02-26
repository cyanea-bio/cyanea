defmodule Cyanea.PreviewFixtures do
  @moduledoc """
  Test helpers for creating blobs with known content for preview testing.
  """

  alias Cyanea.Blobs.{Blob, SpaceFile}
  alias Cyanea.Repo

  @sample_fasta """
  >seq1 test sequence
  ATGCGATCGATCGATCGATCGATCGATCGATCG
  >seq2 another sequence
  GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
  >seq3 third sequence
  ATATATATATGCGCGCGCGCATATATATATATAT
  """

  @sample_csv """
  gene_id,gene_name,expression,pvalue
  ENSG00000001,BRCA1,12.5,0.001
  ENSG00000002,TP53,8.3,0.05
  ENSG00000003,EGFR,15.7,0.003
  ENSG00000004,MYC,22.1,0.0001
  """

  @sample_vcf """
  ##fileformat=VCFv4.2
  ##INFO=<ID=DP,Number=1,Type=Integer>
  #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSample1\tSample2
  chr1\t100\t.\tA\tT\t30\tPASS\tDP=50\tGT\t0/1\t0/0
  chr1\t200\t.\tG\tC\t25\tPASS\tDP=40\tGT\t0/0\t0/1
  chr2\t300\t.\tT\tA\t35\tPASS\tDP=60\tGT\t1/1\t0/1
  """

  @sample_bed """
  chr1\t100\t200\tfeature1\t100\t+
  chr1\t300\t400\tfeature2\t200\t-
  chr2\t500\t600\tfeature3\t150\t+
  """

  @sample_markdown """
  # Test Document

  This is a **markdown** document with some content.

  ## Section 1

  - Item 1
  - Item 2
  - Item 3

  ## Section 2

  Some text with `inline code` and a formula: $E = mc^2$
  """

  def sample_fasta, do: @sample_fasta
  def sample_csv, do: @sample_csv
  def sample_vcf, do: @sample_vcf
  def sample_bed, do: @sample_bed
  def sample_markdown, do: @sample_markdown

  @doc """
  Creates a blob with known content and returns {blob, space_file}.
  """
  def blob_with_content_fixture(space_id, content, opts \\ []) do
    name = Keyword.get(opts, :name, "test-file.txt")
    mime_type = Keyword.get(opts, :mime_type, "application/octet-stream")

    sha256 = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
    s3_key = "blobs/#{String.slice(sha256, 0, 2)}/#{String.slice(sha256, 2, 2)}/#{sha256}"

    blob =
      %Blob{}
      |> Blob.changeset(%{
        sha256: sha256,
        s3_key: s3_key,
        size: byte_size(content),
        mime_type: mime_type
      })
      |> Repo.insert!()

    space_file =
      %SpaceFile{}
      |> SpaceFile.changeset(%{
        space_id: space_id,
        blob_id: blob.id,
        path: name,
        name: name
      })
      |> Repo.insert!()

    {blob, space_file}
  end

  def fasta_blob_fixture(space_id) do
    blob_with_content_fixture(space_id, @sample_fasta,
      name: "sequences.fasta",
      mime_type: "text/plain"
    )
  end

  def csv_blob_fixture(space_id) do
    blob_with_content_fixture(space_id, @sample_csv,
      name: "expression.csv",
      mime_type: "text/csv"
    )
  end

  def vcf_blob_fixture(space_id) do
    blob_with_content_fixture(space_id, @sample_vcf,
      name: "variants.vcf",
      mime_type: "text/plain"
    )
  end
end

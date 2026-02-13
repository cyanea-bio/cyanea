defmodule Cyanea.Formats do
  @moduledoc "Bioinformatics file format parsing: CSV, VCF, BED, GFF3, SAM, BAM."

  import Cyanea.NifHelper
  alias Cyanea.Native

  # ===========================================================================
  # CSV
  # ===========================================================================

  @doc "Get CSV file metadata (row count, columns)."
  @spec csv_info(binary()) :: {:ok, struct()} | {:error, term()}
  def csv_info(path) when is_binary(path),
    do: nif_call(fn -> Native.csv_info(path) end)

  @doc """
  Preview first N rows of a CSV file.

  ## Options

    * `:limit` - number of rows to preview (default: 100)

  """
  @spec csv_preview(binary(), keyword()) :: {:ok, term()} | {:error, term()}
  def csv_preview(path, opts \\ []) when is_binary(path) do
    limit = Keyword.get(opts, :limit, 100)
    nif_call(fn -> Native.csv_preview(path, limit) end)
  end

  # ===========================================================================
  # VCF
  # ===========================================================================

  @doc "Get VCF file statistics (variant counts, chromosomes)."
  @spec vcf_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def vcf_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.vcf_stats(path) end)

  @doc "Parse a VCF file and return all variant records."
  @spec parse_vcf(binary()) :: {:ok, list()} | {:error, term()}
  def parse_vcf(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_vcf(path) end)

  # ===========================================================================
  # BED
  # ===========================================================================

  @doc "Get BED file statistics (record count, total bases, chromosomes)."
  @spec bed_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def bed_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.bed_stats(path) end)

  @doc "Parse a BED file and return all records."
  @spec parse_bed(binary()) :: {:ok, list()} | {:error, term()}
  def parse_bed(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_bed(path) end)

  @doc "Parse a BED file and return genomic intervals."
  @spec parse_bed_intervals(binary()) :: {:ok, list()} | {:error, term()}
  def parse_bed_intervals(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_bed_intervals(path) end)

  # ===========================================================================
  # GFF3
  # ===========================================================================

  @doc "Get GFF3 file statistics (gene/transcript/exon counts, chromosomes)."
  @spec gff3_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def gff3_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.gff3_stats(path) end)

  @doc "Parse a GFF3 file and return all gene records."
  @spec parse_gff3(binary()) :: {:ok, list()} | {:error, term()}
  def parse_gff3(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_gff3(path) end)

  # ===========================================================================
  # SAM/BAM
  # ===========================================================================

  @doc "Get statistics from a SAM file."
  @spec sam_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def sam_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.sam_stats(path) end)

  @doc "Parse a SAM file and return all alignment records."
  @spec parse_sam(binary()) :: {:ok, list()} | {:error, term()}
  def parse_sam(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_sam(path) end)

  @doc "Get statistics from a BAM file."
  @spec bam_stats(binary()) :: {:ok, struct()} | {:error, term()}
  def bam_stats(path) when is_binary(path),
    do: nif_call(fn -> Native.bam_stats(path) end)

  @doc "Parse a BAM file and return all alignment records."
  @spec parse_bam(binary()) :: {:ok, list()} | {:error, term()}
  def parse_bam(path) when is_binary(path),
    do: nif_call(fn -> Native.parse_bam(path) end)
end

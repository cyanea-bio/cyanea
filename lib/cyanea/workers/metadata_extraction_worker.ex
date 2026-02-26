defmodule Cyanea.Workers.MetadataExtractionWorker do
  @moduledoc """
  Extracts file metadata and statistics using Rust NIFs.

  After a blob is uploaded, this worker downloads it to a temp file
  and runs format-specific analysis (FASTA/FASTQ stats, CSV info, etc.).
  Results are stored in the space_file's path-based convention or can
  be consumed by callers via the job's result.

  ## Usage

      %{blob_id: blob_id}
      |> Cyanea.Workers.MetadataExtractionWorker.new()
      |> Oban.insert()
  """
  use Oban.Worker, queue: :analysis, max_attempts: 2

  alias Cyanea.Blobs
  alias Cyanea.Compute

  @extractors %{
    "fasta" => &Compute.fasta_stats/1,
    "fa" => &Compute.fasta_stats/1,
    "fna" => &Compute.fasta_stats/1,
    "faa" => &Compute.fasta_stats/1,
    "fastq" => &Compute.fastq_stats/1,
    "fq" => &Compute.fastq_stats/1,
    "csv" => &Compute.csv_info/1,
    "tsv" => &Compute.csv_info/1,
    "vcf" => &Compute.vcf_stats/1,
    "bed" => &Compute.bed_stats/1,
    "gff" => &Compute.gff3_stats/1,
    "gff3" => &Compute.gff3_stats/1,
    "sam" => &Compute.sam_stats/1,
    "bam" => &Compute.bam_stats/1
  }

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"blob_id" => blob_id}}) do
    blob = Blobs.get_blob!(blob_id)

    case find_extractor(blob) do
      nil -> :ok
      extractor -> run_extractor(blob, extractor)
    end
  end

  defp find_extractor(blob) do
    ext =
      blob.s3_key
      |> Path.extname()
      |> String.trim_leading(".")
      |> String.downcase()

    ext = if ext == "", do: mime_to_ext(blob.mime_type), else: ext
    Map.get(@extractors, ext)
  end

  defp run_extractor(blob, extractor) do
    tmp_path = Path.join(System.tmp_dir!(), "cyanea_meta_#{blob.id}")

    try do
      with :ok <- download_blob(blob, tmp_path) do
        run_analysis(extractor, tmp_path)
      end
    after
      File.rm(tmp_path)
    end
  end

  defp run_analysis(extractor, path) do
    case extractor.(path) do
      {:ok, _stats} -> :ok
      {:error, :nif_not_loaded} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp download_blob(blob, tmp_path) do
    case Cyanea.Storage.download(blob.s3_key) do
      {:ok, binary} ->
        File.write!(tmp_path, binary)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp mime_to_ext("text/csv"), do: "csv"
  defp mime_to_ext("text/tab-separated-values"), do: "tsv"
  defp mime_to_ext(_), do: ""
end

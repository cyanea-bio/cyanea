defmodule Cyanea.Previews do
  @moduledoc """
  Context for generating and caching file previews.

  Detects file types, downloads from S3, runs NIF analysis with
  fallbacks to pure Elixir parsing, and caches results.
  """
  alias Cyanea.Native
  alias Cyanea.Previews.FilePreview
  alias Cyanea.Repo
  alias Cyanea.Storage

  @max_download_size 2 * 1024 * 1024

  @sequence_exts ~w(.fasta .fa .fna .faa .fastq .fq)
  @tabular_exts ~w(.csv .tsv .tab)
  @variant_exts ~w(.vcf)
  @interval_exts ~w(.bed .gff .gff3 .gtf)
  @structure_exts ~w(.pdb .ent)
  @image_exts ~w(.png .jpg .jpeg .gif .svg .webp .tiff)
  @pdf_exts ~w(.pdf)
  @markdown_exts ~w(.md .markdown)

  # -- Type Detection --

  @doc """
  Detects the preview type from a filename and optional MIME type.
  """
  def preview_type(filename, mime_type \\ nil) do
    ext = filename |> Path.extname() |> String.downcase()

    cond do
      ext in @sequence_exts -> :sequence
      ext in @tabular_exts -> :tabular
      ext in @variant_exts -> :variant
      ext in @interval_exts -> :interval
      ext in @structure_exts -> :structure
      ext in @image_exts -> :image
      ext in @pdf_exts -> :pdf
      ext in @markdown_exts -> :markdown
      text_mime?(mime_type) -> :text
      true -> :unsupported
    end
  end

  # -- Preview Retrieval --

  @doc """
  Gets an existing preview from cache or generates a new one.
  """
  def get_or_generate_preview(blob, filename) do
    case get_cached_preview(blob.id) do
      %FilePreview{} = preview ->
        {:ok, preview}

      nil ->
        type = preview_type(filename, blob.mime_type)
        generate_preview(blob, type)
    end
  end

  @doc """
  Generates a preview for a blob and caches the result.
  """
  def generate_preview(blob, type) when type in [:image, :pdf, :unsupported] do
    preview_data =
      case type do
        :image -> %{"mime_type" => blob.mime_type, "size" => blob.size}
        :pdf -> %{"size" => blob.size}
        :unsupported -> %{"size" => blob.size, "mime_type" => blob.mime_type}
      end

    create_preview(blob.id, type, preview_data)
  end

  def generate_preview(blob, type) do
    case Storage.download(blob.s3_key) do
      {:ok, content} ->
        content = truncate_content(content, @max_download_size)
        preview_data = analyze_content(type, content)
        create_preview(blob.id, type, preview_data)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # -- Content Analysis --

  defp analyze_content(:sequence, content), do: preview_data_for_sequence(content)
  defp analyze_content(:tabular, content), do: preview_data_for_tabular(content)
  defp analyze_content(:variant, content), do: preview_data_for_variant(content)
  defp analyze_content(:interval, content), do: preview_data_for_interval(content)
  defp analyze_content(:structure, content), do: preview_data_for_structure(content)
  defp analyze_content(:markdown, content), do: preview_data_for_markdown(content)
  defp analyze_content(:text, content), do: preview_data_for_text(content)
  defp analyze_content(_, content), do: preview_data_for_text(content)

  @doc false
  def preview_data_for_sequence(content) do
    is_fastq = String.starts_with?(content, "@")

    try_nif(
      fn ->
        if is_fastq do
          stats = Native.fastq_stats(content)

          %{
            "format" => "fastq",
            "sequence_count" => stats.num_sequences,
            "total_length" => stats.total_length,
            "gc_content" => stats.gc_content,
            "min_length" => stats.min_length,
            "max_length" => stats.max_length,
            "avg_quality" => stats.avg_quality
          }
        else
          stats = Native.fasta_stats(content)

          %{
            "format" => "fasta",
            "sequence_count" => stats.num_sequences,
            "total_length" => stats.total_length,
            "gc_content" => stats.gc_content,
            "min_length" => stats.min_length,
            "max_length" => stats.max_length
          }
        end
      end,
      fn ->
        fallback_sequence_stats(content, is_fastq)
      end
    )
  end

  @doc false
  def preview_data_for_tabular(content) do
    try_nif(
      fn ->
        info = Native.csv_info(content)

        %{
          "row_count" => info.row_count,
          "column_count" => info.column_count,
          "columns" => info.columns,
          "preview_rows" => parse_preview_rows(content, 50)
        }
      end,
      fn ->
        fallback_tabular_stats(content)
      end
    )
  end

  @doc false
  def preview_data_for_variant(content) do
    try_nif(
      fn ->
        stats = Native.vcf_stats(content)

        %{
          "variant_count" => stats.variant_count,
          "sample_count" => stats.sample_count,
          "samples" => stats.samples,
          "contigs" => stats.contigs
        }
      end,
      fn ->
        fallback_variant_stats(content)
      end
    )
  end

  @doc false
  def preview_data_for_interval(content) do
    # Detect format by content
    is_gff = String.contains?(content, "##gff")

    try_nif(
      fn ->
        if is_gff do
          stats = Native.gff3_stats(content)

          %{
            "format" => "gff3",
            "feature_count" => stats.feature_count,
            "feature_types" => stats.feature_types,
            "sequences" => stats.sequences
          }
        else
          stats = Native.bed_stats(content)

          %{
            "format" => "bed",
            "region_count" => stats.region_count,
            "chromosomes" => stats.chromosomes,
            "total_coverage" => stats.total_coverage
          }
        end
      end,
      fn ->
        fallback_interval_stats(content, is_gff)
      end
    )
  end

  @doc false
  def preview_data_for_structure(content) do
    try_nif(
      fn ->
        info = Native.pdb_info(content)

        %{
          "atom_count" => info.atom_count,
          "residue_count" => info.residue_count,
          "chain_count" => info.chain_count,
          "chains" => info.chains
        }
      end,
      fn ->
        fallback_structure_stats(content)
      end
    )
  end

  @doc false
  def preview_data_for_markdown(content) do
    case Earmark.as_html(content) do
      {:ok, html, _} -> %{"html" => html, "line_count" => count_lines(content)}
      {:error, _, _} -> %{"html" => "<pre>#{content}</pre>", "line_count" => count_lines(content)}
    end
  end

  @doc false
  def preview_data_for_text(content) do
    lines = content |> String.split("\n") |> Enum.take(500)

    %{
      "line_count" => count_lines(content),
      "preview_lines" => lines,
      "truncated" => count_lines(content) > 500
    }
  end

  # -- Fallback Parsers --

  defp fallback_sequence_stats(content, is_fastq) do
    lines = String.split(content, "\n")

    if is_fastq do
      # FASTQ: every 4 lines is a record (@header, sequence, +, quality)
      records = div(length(lines), 4)
      seq_lines = lines |> Enum.drop(1) |> Enum.take_every(4)
      total_length = seq_lines |> Enum.map(&String.length/1) |> Enum.sum()
      gc = compute_gc_content(Enum.join(seq_lines))

      %{
        "format" => "fastq",
        "sequence_count" => records,
        "total_length" => total_length,
        "gc_content" => gc
      }
    else
      # FASTA: count > lines
      headers = Enum.filter(lines, &String.starts_with?(&1, ">"))
      seq_lines = Enum.reject(lines, &(String.starts_with?(&1, ">") or &1 == ""))
      seq_content = Enum.join(seq_lines)
      gc = compute_gc_content(seq_content)

      %{
        "format" => "fasta",
        "sequence_count" => length(headers),
        "total_length" => String.length(seq_content),
        "gc_content" => gc
      }
    end
  end

  defp fallback_tabular_stats(content) do
    lines = content |> String.split("\n") |> Enum.reject(&(&1 == ""))

    case lines do
      [] ->
        %{"row_count" => 0, "column_count" => 0, "columns" => [], "preview_rows" => []}

      [header | data_lines] ->
        separator = detect_separator(header)
        columns = String.split(header, separator)
        row_count = length(data_lines)

        preview_rows =
          data_lines
          |> Enum.take(50)
          |> Enum.map(&String.split(&1, separator))

        %{
          "row_count" => row_count,
          "column_count" => length(columns),
          "columns" => columns,
          "preview_rows" => preview_rows
        }
    end
  end

  defp fallback_variant_stats(content) do
    lines = String.split(content, "\n")
    header_lines = Enum.filter(lines, &String.starts_with?(&1, "##"))
    data_lines = Enum.reject(lines, &(String.starts_with?(&1, "#") or &1 == ""))

    samples =
      lines
      |> Enum.find(&String.starts_with?(&1, "#CHROM"))
      |> case do
        nil -> []
        line -> line |> String.split("\t") |> Enum.drop(9)
      end

    %{
      "variant_count" => length(data_lines),
      "sample_count" => length(samples),
      "samples" => Enum.take(samples, 20),
      "header_line_count" => length(header_lines)
    }
  end

  defp fallback_interval_stats(content, is_gff) do
    lines = content |> String.split("\n") |> Enum.reject(&(String.starts_with?(&1, "#") or &1 == ""))

    if is_gff do
      feature_types =
        lines
        |> Enum.map(fn line ->
          case String.split(line, "\t") do
            [_, _, type | _] -> type
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.frequencies()

      %{
        "format" => "gff3",
        "feature_count" => length(lines),
        "feature_types" => feature_types
      }
    else
      chromosomes =
        lines
        |> Enum.map(fn line ->
          case String.split(line, "\t") do
            [chrom | _] -> chrom
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.frequencies()

      %{
        "format" => "bed",
        "region_count" => length(lines),
        "chromosomes" => chromosomes
      }
    end
  end

  defp fallback_structure_stats(content) do
    lines = String.split(content, "\n")
    atom_lines = Enum.filter(lines, &String.starts_with?(&1, "ATOM"))
    hetatm_lines = Enum.filter(lines, &String.starts_with?(&1, "HETATM"))

    chains =
      atom_lines
      |> Enum.map(fn line ->
        if String.length(line) >= 22, do: String.at(line, 21), else: nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    %{
      "atom_count" => length(atom_lines) + length(hetatm_lines),
      "residue_count" => nil,
      "chain_count" => length(chains),
      "chains" => chains
    }
  end

  # -- Helpers --

  defp get_cached_preview(blob_id) do
    Repo.get_by(FilePreview, blob_id: blob_id)
  end

  defp create_preview(blob_id, type, data) do
    %FilePreview{}
    |> FilePreview.changeset(%{
      blob_id: blob_id,
      preview_type: Atom.to_string(type),
      preview_data: data,
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :blob_id)
  end

  defp try_nif(nif_fn, fallback_fn) do
    try do
      nif_fn.()
    rescue
      ErlangError -> fallback_fn.()
      UndefinedFunctionError -> fallback_fn.()
    end
  end

  defp truncate_content(content, max_size) when byte_size(content) > max_size do
    binary_part(content, 0, max_size)
  end

  defp truncate_content(content, _max_size), do: content

  defp text_mime?(nil), do: false

  defp text_mime?(mime) do
    String.starts_with?(mime, "text/") or mime in ~w(application/json application/xml)
  end

  defp compute_gc_content(""), do: 0.0

  defp compute_gc_content(seq) do
    seq = String.upcase(seq)
    gc = seq |> String.graphemes() |> Enum.count(&(&1 in ~w(G C)))
    total = String.length(seq)
    if total > 0, do: gc / total, else: 0.0
  end

  defp count_lines(content) do
    content |> String.split("\n") |> length()
  end

  defp detect_separator(line) do
    cond do
      String.contains?(line, "\t") -> "\t"
      String.contains?(line, ",") -> ","
      true -> ","
    end
  end

  defp parse_preview_rows(content, max_rows) do
    lines = content |> String.split("\n") |> Enum.reject(&(&1 == ""))

    case lines do
      [] ->
        []

      [header | data] ->
        separator = detect_separator(header)
        data |> Enum.take(max_rows) |> Enum.map(&String.split(&1, separator))
    end
  end
end

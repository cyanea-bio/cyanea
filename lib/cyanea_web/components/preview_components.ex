defmodule CyaneaWeb.PreviewComponents do
  @moduledoc """
  Components for rendering file previews of various types.
  """
  use Phoenix.Component

  import CyaneaWeb.CoreComponents
  import CyaneaWeb.UIComponents

  attr :preview_type, :string, required: true
  attr :preview_data, :map, required: true
  attr :download_url, :string, default: nil
  attr :blob, :map, default: nil

  def file_preview(assigns) do
    ~H"""
    <div>
      <%= case @preview_type do %>
        <% "sequence" -> %>
          <.sequence_preview data={@preview_data} />
        <% "tabular" -> %>
          <.tabular_preview data={@preview_data} />
        <% "variant" -> %>
          <.variant_preview data={@preview_data} />
        <% "interval" -> %>
          <.interval_preview data={@preview_data} />
        <% "structure" -> %>
          <.structure_preview data={@preview_data} />
        <% "image" -> %>
          <.image_preview download_url={@download_url} />
        <% "pdf" -> %>
          <.pdf_preview download_url={@download_url} />
        <% "markdown" -> %>
          <.markdown_preview data={@preview_data} />
        <% "text" -> %>
          <.text_preview data={@preview_data} />
        <% _ -> %>
          <.unsupported_preview blob={@blob} download_url={@download_url} />
      <% end %>
    </div>
    """
  end

  attr :data, :map, required: true

  def sequence_preview(assigns) do
    ~H"""
    <div>
      <h3 class="mb-4 text-sm font-semibold text-slate-900 dark:text-white">Sequence Statistics</h3>
      <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        <.preview_stat label="Format" value={String.upcase(@data["format"] || "FASTA")} />
        <.preview_stat
          label="Sequences"
          value={format_number(@data["sequence_count"])}
        />
        <.preview_stat
          label="Total length"
          value={"#{format_number(@data["total_length"])} bp"}
        />
        <.preview_stat
          label="GC content"
          value={format_percent(@data["gc_content"])}
        />
        <.preview_stat
          :if={@data["min_length"]}
          label="Min length"
          value={"#{format_number(@data["min_length"])} bp"}
        />
        <.preview_stat
          :if={@data["max_length"]}
          label="Max length"
          value={"#{format_number(@data["max_length"])} bp"}
        />
        <.preview_stat
          :if={@data["avg_quality"]}
          label="Avg quality"
          value={format_decimal(@data["avg_quality"])}
        />
      </div>
    </div>
    """
  end

  attr :data, :map, required: true

  def tabular_preview(assigns) do
    columns = assigns.data["columns"] || []
    preview_rows = assigns.data["preview_rows"] || []
    assigns = assign(assigns, columns: columns, preview_rows: preview_rows)

    ~H"""
    <div>
      <div class="mb-4 flex items-center justify-between">
        <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Tabular Preview</h3>
        <div class="flex items-center gap-4 text-xs text-slate-500">
          <span><%= format_number(@data["row_count"]) %> rows</span>
          <span><%= @data["column_count"] %> columns</span>
        </div>
      </div>
      <div
        :if={@preview_rows != []}
        id="csv-viewer"
        phx-hook="CsvViewer"
        data-columns={Jason.encode!(@columns)}
        data-rows={Jason.encode!(@preview_rows)}
        class="overflow-x-auto"
      >
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-b border-slate-200 dark:border-slate-700">
              <th
                :for={col <- @columns}
                class="cursor-pointer px-3 py-2 text-xs font-medium text-slate-500 hover:text-slate-700 dark:text-slate-400"
              >
                <%= col %>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={row <- @preview_rows}
              class="border-b border-slate-100 last:border-0 dark:border-slate-700/50"
            >
              <td
                :for={cell <- row}
                class="whitespace-nowrap px-3 py-1.5 text-xs text-slate-700 dark:text-slate-300"
              >
                <%= cell %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p :if={@preview_rows == []} class="text-sm text-slate-500">No data rows to preview.</p>
    </div>
    """
  end

  attr :data, :map, required: true

  def variant_preview(assigns) do
    ~H"""
    <div>
      <h3 class="mb-4 text-sm font-semibold text-slate-900 dark:text-white">VCF Statistics</h3>
      <div class="grid grid-cols-2 gap-4 sm:grid-cols-3">
        <.preview_stat label="Variants" value={format_number(@data["variant_count"])} />
        <.preview_stat label="Samples" value={format_number(@data["sample_count"])} />
      </div>
      <div :if={@data["samples"] && @data["samples"] != []} class="mt-4">
        <h4 class="mb-2 text-xs font-medium text-slate-600 dark:text-slate-400">Samples</h4>
        <div class="flex flex-wrap gap-1">
          <.badge :for={sample <- @data["samples"]} color={:gray} size={:xs}><%= sample %></.badge>
        </div>
      </div>
      <div :if={@data["contigs"] && @data["contigs"] != []} class="mt-4">
        <h4 class="mb-2 text-xs font-medium text-slate-600 dark:text-slate-400">Contigs</h4>
        <div class="flex flex-wrap gap-1">
          <.badge :for={contig <- Enum.take(@data["contigs"] || [], 20)} color={:gray} size={:xs}>
            <%= contig %>
          </.badge>
        </div>
      </div>
    </div>
    """
  end

  attr :data, :map, required: true

  def interval_preview(assigns) do
    ~H"""
    <div>
      <h3 class="mb-4 text-sm font-semibold text-slate-900 dark:text-white">
        <%= String.upcase(@data["format"] || "BED") %> Statistics
      </h3>
      <div class="grid grid-cols-2 gap-4 sm:grid-cols-3">
        <.preview_stat
          :if={@data["region_count"]}
          label="Regions"
          value={format_number(@data["region_count"])}
        />
        <.preview_stat
          :if={@data["feature_count"]}
          label="Features"
          value={format_number(@data["feature_count"])}
        />
        <.preview_stat
          :if={@data["total_coverage"]}
          label="Total coverage"
          value={"#{format_number(@data["total_coverage"])} bp"}
        />
      </div>
      <div :if={@data["feature_types"]} class="mt-4">
        <h4 class="mb-2 text-xs font-medium text-slate-600 dark:text-slate-400">Feature types</h4>
        <div class="flex flex-wrap gap-1">
          <.badge :for={{type, count} <- @data["feature_types"] || %{}} color={:primary} size={:xs}>
            <%= type %> (<%= count %>)
          </.badge>
        </div>
      </div>
      <div :if={@data["chromosomes"]} class="mt-4">
        <h4 class="mb-2 text-xs font-medium text-slate-600 dark:text-slate-400">Chromosomes</h4>
        <div class="flex flex-wrap gap-1">
          <.badge :for={{chrom, count} <- @data["chromosomes"] || %{}} color={:gray} size={:xs}>
            <%= chrom %> (<%= count %>)
          </.badge>
        </div>
      </div>
    </div>
    """
  end

  attr :data, :map, required: true

  def structure_preview(assigns) do
    ~H"""
    <div>
      <h3 class="mb-4 text-sm font-semibold text-slate-900 dark:text-white">PDB Structure</h3>
      <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <.preview_stat label="Chains" value={format_number(@data["chain_count"])} />
        <.preview_stat label="Atoms" value={format_number(@data["atom_count"])} />
        <.preview_stat
          :if={@data["residue_count"]}
          label="Residues"
          value={format_number(@data["residue_count"])}
        />
      </div>
      <div :if={@data["chains"] && @data["chains"] != []} class="mt-4">
        <h4 class="mb-2 text-xs font-medium text-slate-600 dark:text-slate-400">Chain IDs</h4>
        <div class="flex flex-wrap gap-1">
          <.badge :for={chain <- @data["chains"]} color={:primary} size={:xs}><%= chain %></.badge>
        </div>
      </div>
    </div>
    """
  end

  attr :download_url, :string, required: true

  def image_preview(assigns) do
    ~H"""
    <div id="image-viewer" phx-hook="ImageViewer" class="relative overflow-hidden rounded-lg border border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-900">
      <div class="absolute right-2 top-2 z-10 flex items-center gap-1">
        <button data-action="zoom-in" class="rounded bg-white/80 p-1.5 text-slate-600 shadow hover:bg-white dark:bg-slate-800/80 dark:text-slate-300">
          <.icon name="hero-magnifying-glass-plus" class="h-4 w-4" />
        </button>
        <button data-action="zoom-out" class="rounded bg-white/80 p-1.5 text-slate-600 shadow hover:bg-white dark:bg-slate-800/80 dark:text-slate-300">
          <.icon name="hero-magnifying-glass-minus" class="h-4 w-4" />
        </button>
        <button data-action="zoom-reset" class="rounded bg-white/80 p-1.5 text-slate-600 shadow hover:bg-white dark:bg-slate-800/80 dark:text-slate-300">
          <.icon name="hero-arrow-path" class="h-4 w-4" />
        </button>
      </div>
      <div class="flex min-h-[300px] items-center justify-center p-4" data-image-container>
        <img src={@download_url} class="max-h-[600px] max-w-full object-contain transition-transform duration-200" data-image />
      </div>
    </div>
    """
  end

  attr :download_url, :string, required: true

  def pdf_preview(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-slate-200 dark:border-slate-700">
      <iframe src={@download_url} class="h-[700px] w-full" />
    </div>
    """
  end

  attr :data, :map, required: true

  def markdown_preview(assigns) do
    ~H"""
    <div
      id="markdown-viewer"
      phx-hook="MarkdownViewer"
      class="prose prose-slate max-w-none dark:prose-invert"
    >
      <%= Phoenix.HTML.raw(@data["html"] || "") %>
    </div>
    """
  end

  attr :data, :map, required: true

  def text_preview(assigns) do
    lines = assigns.data["preview_lines"] || []
    assigns = assign(assigns, lines: lines)

    ~H"""
    <div>
      <div class="mb-2 flex items-center justify-between">
        <span class="text-xs text-slate-500">
          <%= @data["line_count"] %> lines
          <span :if={@data["truncated"]}>(showing first 500)</span>
        </span>
      </div>
      <div class="overflow-x-auto rounded-lg border border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-900">
        <table class="w-full">
          <tbody>
            <tr :for={{line, idx} <- Enum.with_index(@lines, 1)}>
              <td class="select-none px-3 py-0.5 text-right text-xs text-slate-400 align-top w-10"><%= idx %></td>
              <td class="px-2 py-0.5 text-xs font-mono whitespace-pre text-slate-700 dark:text-slate-300"><%= line %></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :blob, :map, default: nil
  attr :download_url, :string, default: nil

  def unsupported_preview(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-12">
      <.icon name="hero-document" class="h-12 w-12 text-slate-300" />
      <p class="mt-4 text-sm font-medium text-slate-600 dark:text-slate-400">
        Preview not available for this file type.
      </p>
      <p :if={@blob} class="mt-1 text-xs text-slate-500">
        <%= @blob.mime_type || "Unknown type" %> &middot; <%= CyaneaWeb.Formatters.format_size(@blob.size) %>
      </p>
      <.link
        :if={@download_url}
        href={@download_url}
        class="mt-4 inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
      >
        <.icon name="hero-arrow-down-tray" class="h-4 w-4" />
        Download
      </.link>
    </div>
    """
  end

  # -- Stat helpers --

  defp preview_stat(assigns) do
    ~H"""
    <div class="rounded-lg border border-slate-200 bg-slate-50 p-3 dark:border-slate-700 dark:bg-slate-800">
      <dt class="text-xs text-slate-500 dark:text-slate-400"><%= @label %></dt>
      <dd class="mt-1 text-lg font-semibold text-slate-900 dark:text-white"><%= @value %></dd>
    </div>
    """
  end

  defp format_number(nil), do: "-"
  defp format_number(n) when is_integer(n) and n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when is_integer(n) and n >= 1_000, do: "#{Float.round(n / 1_000, 1)}K"
  defp format_number(n) when is_number(n), do: "#{n}"
  defp format_number(_), do: "-"

  defp format_percent(nil), do: "-"
  defp format_percent(n) when is_number(n), do: "#{Float.round(n * 100, 1)}%"
  defp format_percent(_), do: "-"

  defp format_decimal(nil), do: "-"
  defp format_decimal(n) when is_number(n), do: "#{Float.round(n * 1.0, 1)}"
  defp format_decimal(_), do: "-"
end

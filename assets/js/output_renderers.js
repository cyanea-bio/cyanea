// Pure rendering functions for notebook cell outputs.
// Each takes data and returns an HTML string.

import { renderSequence } from "./hooks/sequence_viewer.js"
import { renderAlignment } from "./hooks/alignment_viewer.js"

export function renderTextOutput(data) {
  const text = typeof data === "string" ? data : JSON.stringify(data, null, 2)
  const escaped = escapeHtml(text)
  return `<pre class="whitespace-pre-wrap text-sm font-mono text-slate-800 dark:text-slate-200">${escaped}</pre>`
}

export function renderTableOutput(data) {
  if (!data || data.length === 0) {
    return `<div class="text-sm text-slate-500 italic">Empty table</div>`
  }

  // Limit rows
  const maxRows = 100
  const rows = data.slice(0, maxRows)
  const truncated = data.length > maxRows

  // Handle array of objects
  if (typeof rows[0] === "object" && !Array.isArray(rows[0])) {
    const keys = Object.keys(rows[0])
    const headerHtml = keys
      .map(
        (k) =>
          `<th class="border border-slate-200 dark:border-slate-600 bg-slate-50 dark:bg-slate-800 px-3 py-1.5 text-left text-xs font-medium text-slate-600 dark:text-slate-300">${escapeHtml(String(k))}</th>`
      )
      .join("")

    const bodyHtml = rows
      .map(
        (row, i) =>
          `<tr class="${i % 2 === 0 ? "bg-white dark:bg-slate-900" : "bg-slate-50/50 dark:bg-slate-800/30"}">${keys.map((k) => `<td class="border border-slate-200 dark:border-slate-600 px-3 py-1.5 text-sm text-slate-700 dark:text-slate-300 font-mono">${escapeHtml(formatValue(row[k]))}</td>`).join("")}</tr>`
      )
      .join("")

    return `<div class="overflow-x-auto"><table class="w-full border-collapse text-sm"><thead><tr>${headerHtml}</tr></thead><tbody>${bodyHtml}</tbody></table>${truncated ? `<div class="text-xs text-slate-400 mt-1">Showing ${maxRows} of ${data.length} rows</div>` : ""}</div>`
  }

  // Handle array of arrays
  if (Array.isArray(rows[0])) {
    const bodyHtml = rows
      .map(
        (row, i) =>
          `<tr class="${i % 2 === 0 ? "bg-white dark:bg-slate-900" : "bg-slate-50/50 dark:bg-slate-800/30"}">${row.map((val) => `<td class="border border-slate-200 dark:border-slate-600 px-3 py-1.5 text-sm text-slate-700 dark:text-slate-300 font-mono">${escapeHtml(formatValue(val))}</td>`).join("")}</tr>`
      )
      .join("")

    return `<div class="overflow-x-auto"><table class="w-full border-collapse text-sm"><tbody>${bodyHtml}</tbody></table>${truncated ? `<div class="text-xs text-slate-400 mt-1">Showing ${maxRows} of ${data.length} rows</div>` : ""}</div>`
  }

  return renderTextOutput(data)
}

export function renderErrorOutput(message) {
  const escaped = escapeHtml(typeof message === "string" ? message : String(message))
  return `<div class="rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 p-3">
    <div class="flex items-start gap-2">
      <svg class="h-4 w-4 text-red-500 mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <pre class="text-sm text-red-700 dark:text-red-400 whitespace-pre-wrap font-mono">${escaped}</pre>
    </div>
  </div>`
}

export function renderSequenceOutput(data) {
  const container = document.createElement("div")
  renderSequence(container, typeof data === "string" ? data : data.sequence || "", null)
  return container.innerHTML
}

export function renderAlignmentOutput(data) {
  const container = document.createElement("div")
  renderAlignment(container, data)
  return container.innerHTML
}

// Auto-detect and dispatch to the right renderer
export function renderOutput(output) {
  if (!output) return ""

  const { type, data } = output

  switch (type) {
    case "error":
      return renderErrorOutput(data)
    case "table":
      return renderTableOutput(data)
    case "sequence":
      return renderSequenceOutput(data)
    case "alignment":
      return renderAlignmentOutput(data)
    case "text":
    default:
      return renderTextOutput(data)
  }
}

function escapeHtml(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
}

function formatValue(val) {
  if (val === null || val === undefined) return ""
  if (typeof val === "number") {
    return Number.isInteger(val) ? String(val) : val.toFixed(6).replace(/\.?0+$/, "")
  }
  return String(val)
}

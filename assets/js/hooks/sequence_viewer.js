import { loadWasm, Seq } from "../wasm.js"

// Color scheme for nucleotides
const COLORS = {
  A: { fg: "#15803d", bg: "#dcfce7" }, // green
  T: { fg: "#dc2626", bg: "#fee2e2" }, // red
  U: { fg: "#dc2626", bg: "#fee2e2" }, // red (RNA)
  G: { fg: "#d97706", bg: "#fef3c7" }, // amber
  C: { fg: "#2563eb", bg: "#dbeafe" }, // blue
}
const DEFAULT_COLOR = { fg: "#475569", bg: "#f1f5f9" } // slate

const CHARS_PER_LINE = 80
const POS_INTERVAL = 10

function colorFor(ch) {
  return COLORS[ch.toUpperCase()] || DEFAULT_COLOR
}

function detectType(seq) {
  const upper = seq.toUpperCase()
  if (/^[ACGTN\s]+$/.test(upper)) return "DNA"
  if (/^[ACGUN\s]+$/.test(upper)) return "RNA"
  return "Protein"
}

export function renderSequence(el, sequence, label) {
  const clean = sequence.replace(/^>.*\n?/, "").replace(/\s+/g, "")
  if (!clean) {
    el.innerHTML = `<div class="p-6 text-sm text-slate-500">No sequence data</div>`
    return
  }

  const type = detectType(clean)
  let gcContent = null
  let isValid = true

  try {
    const alphabet = type === "RNA" ? "rna" : type === "DNA" ? "dna" : "protein"
    isValid = Seq.validate(clean, alphabet)
  } catch { isValid = false }

  if (type === "DNA" || type === "RNA") {
    try { gcContent = Seq.gcContent(clean) } catch { /* skip */ }
  }

  // Build color-coded sequence lines
  const lines = []
  for (let i = 0; i < clean.length; i += CHARS_PER_LINE) {
    const chunk = clean.slice(i, i + CHARS_PER_LINE)
    let html = ""

    // Position markers
    const posMarkers = []
    for (let j = 0; j < chunk.length; j++) {
      if ((i + j) % POS_INTERVAL === 0) {
        posMarkers.push({ offset: j, pos: i + j + 1 })
      }
    }

    // Ruler line
    let ruler = ""
    let lastEnd = 0
    for (const m of posMarkers) {
      const label = String(m.pos)
      const padLen = m.offset - lastEnd
      ruler += " ".repeat(Math.max(0, padLen)) + label
      lastEnd = m.offset + label.length
    }

    // Colored bases
    for (const ch of chunk) {
      const c = colorFor(ch)
      html += `<span style="color:${c.fg}">${ch}</span>`
    }

    lines.push({ pos: i + 1, html, ruler })
  }

  const seqHtml = lines.map(l => `
    <div class="flex gap-0 font-mono text-sm leading-relaxed">
      <span class="select-none w-14 text-right pr-3 text-slate-400 shrink-0">${l.pos}</span>
      <div>
        <div class="text-[10px] text-slate-300 dark:text-slate-600 leading-none whitespace-pre">${l.ruler}</div>
        <div class="whitespace-pre">${l.html}</div>
      </div>
    </div>
  `).join("")

  // Stats panel
  const stats = [
    { label: "Length", value: clean.length.toLocaleString() + " bp" },
    { label: "Type", value: type },
  ]
  if (gcContent !== null) {
    stats.push({ label: "GC%", value: (gcContent * 100).toFixed(1) + "%" })
  }
  stats.push({
    label: "Valid",
    value: isValid
      ? `<span class="text-emerald-600 dark:text-emerald-400">Yes</span>`
      : `<span class="text-red-600 dark:text-red-400">No</span>`
  })

  const statsHtml = stats.map(s =>
    `<div class="flex items-center gap-2">
      <span class="text-xs text-slate-500 dark:text-slate-400">${s.label}:</span>
      <span class="text-xs font-medium text-slate-700 dark:text-slate-200">${s.value}</span>
    </div>`
  ).join("")

  const isDna = type === "DNA"

  el.innerHTML = `
    <div class="overflow-hidden rounded-lg border border-slate-200 dark:border-slate-700">
      ${label ? `<div class="border-b border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 px-4 py-2">
        <span class="text-xs font-medium text-slate-600 dark:text-slate-300">${label}</span>
      </div>` : ""}
      <div class="flex flex-wrap items-center gap-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2">
        ${statsHtml}
      </div>
      <div class="overflow-x-auto bg-white dark:bg-slate-900 p-4 max-h-96 overflow-y-auto">
        ${seqHtml}
      </div>
      <div class="flex items-center gap-2 border-t border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 px-4 py-2">
        ${isDna ? `
          <button data-action="reverse-complement" class="inline-flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 transition">
            Rev. Comp.
          </button>
          <button data-action="translate" class="inline-flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 transition">
            Translate
          </button>
          <button data-action="find-orfs" class="inline-flex items-center gap-1 rounded px-2 py-1 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 transition">
            Find ORFs
          </button>
        ` : ""}
      </div>
    </div>
  `

  // Wire action buttons
  el.querySelectorAll("[data-action]").forEach(btn => {
    btn.addEventListener("click", () => {
      const action = btn.dataset.action
      el._hook.pushEvent(action, { sequence: clean })
    })
  })
}

const SequenceViewer = {
  async mounted() {
    this.el._hook = this
    try {
      await loadWasm()
      const seq = this.el.dataset.sequence || ""
      const label = this.el.dataset.label || null
      renderSequence(this.el, seq, label)
    } catch (err) {
      this.el.innerHTML = `<div class="p-4 text-sm text-red-600">Failed to load WASM: ${err.message}</div>`
    }

    this.handleEvent("render-sequence", ({ sequence, label }) => {
      renderSequence(this.el, sequence, label)
    })
  },

  updated() {
    const seq = this.el.dataset.sequence || ""
    const label = this.el.dataset.label || null
    renderSequence(this.el, seq, label)
  }
}

export default SequenceViewer

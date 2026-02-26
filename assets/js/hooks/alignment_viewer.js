import { loadWasm, Align } from "../wasm.js"

function bytesToString(bytes) {
  return String.fromCharCode(...bytes)
}

export function renderAlignment(el, result) {
  const query = bytesToString(result.aligned_query)
  const target = bytesToString(result.aligned_target)

  // Build match line
  let matchLine = ""
  let matches = 0
  let mismatches = 0
  let gaps = 0
  for (let i = 0; i < query.length; i++) {
    const q = query[i]
    const t = target[i]
    if (q === "-" || t === "-") {
      matchLine += " "
      gaps++
    } else if (q.toUpperCase() === t.toUpperCase()) {
      matchLine += "|"
      matches++
    } else {
      matchLine += "."
      mismatches++
    }
  }

  const totalAligned = matches + mismatches
  const identity = totalAligned > 0 ? ((matches / totalAligned) * 100).toFixed(1) : "0.0"

  // Build CIGAR string from ops
  let cigarStr = ""
  if (result.cigar) {
    for (const op of result.cigar) {
      for (const [key, val] of Object.entries(op)) {
        const code = { Match: "=", Mismatch: "X", Insertion: "I", Deletion: "D",
                       AlnMatch: "M", Skip: "N", SoftClip: "S", HardClip: "H", Padding: "P" }[key] || "?"
        cigarStr += val + code
      }
    }
  }

  // Render in blocks of 60
  const blockSize = 60
  const blocks = []
  for (let i = 0; i < query.length; i += blockSize) {
    const qBlock = query.slice(i, i + blockSize)
    const mBlock = matchLine.slice(i, i + blockSize)
    const tBlock = target.slice(i, i + blockSize)

    // Color-coded rendering
    let qHtml = "", mHtml = "", tHtml = ""
    for (let j = 0; j < qBlock.length; j++) {
      const q = qBlock[j], t = tBlock[j], m = mBlock[j]
      if (m === "|") {
        qHtml += `<span class="text-emerald-700 dark:text-emerald-400">${q}</span>`
        mHtml += `<span class="text-emerald-600 dark:text-emerald-500">|</span>`
        tHtml += `<span class="text-emerald-700 dark:text-emerald-400">${t}</span>`
      } else if (q === "-" || t === "-") {
        qHtml += `<span class="text-slate-400">${q}</span>`
        mHtml += `<span class="text-slate-300"> </span>`
        tHtml += `<span class="text-slate-400">${t}</span>`
      } else {
        qHtml += `<span class="text-red-600 dark:text-red-400">${q}</span>`
        mHtml += `<span class="text-red-400">.</span>`
        tHtml += `<span class="text-red-600 dark:text-red-400">${t}</span>`
      }
    }

    blocks.push({ pos: i + 1, qHtml, mHtml, tHtml })
  }

  const blocksHtml = blocks.map(b => `
    <div class="space-y-0 font-mono text-sm leading-snug">
      <div class="flex">
        <span class="select-none w-14 text-right pr-3 text-slate-400 shrink-0 text-xs">Qry</span>
        <span class="whitespace-pre">${b.qHtml}</span>
      </div>
      <div class="flex">
        <span class="select-none w-14 shrink-0"></span>
        <span class="whitespace-pre">${b.mHtml}</span>
      </div>
      <div class="flex">
        <span class="select-none w-14 text-right pr-3 text-slate-400 shrink-0 text-xs">Ref</span>
        <span class="whitespace-pre">${b.tHtml}</span>
      </div>
    </div>
  `).join("")

  // Stats header
  const statsItems = [
    { label: "Score", value: result.score },
    { label: "Identity", value: identity + "%" },
    { label: "Matches", value: matches },
    { label: "Mismatches", value: mismatches },
    { label: "Gaps", value: gaps },
  ]

  const statsHtml = statsItems.map(s =>
    `<div class="flex items-center gap-1.5">
      <span class="text-xs text-slate-500 dark:text-slate-400">${s.label}:</span>
      <span class="text-xs font-medium text-slate-700 dark:text-slate-200">${s.value}</span>
    </div>`
  ).join("")

  el.innerHTML = `
    <div class="overflow-hidden rounded-lg border border-slate-200 dark:border-slate-700">
      <div class="flex flex-wrap items-center gap-4 border-b border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 px-4 py-2">
        ${statsHtml}
      </div>
      ${cigarStr ? `<div class="border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2">
        <span class="text-xs text-slate-500 dark:text-slate-400">CIGAR:</span>
        <code class="ml-1 text-xs text-slate-700 dark:text-slate-200 break-all">${cigarStr}</code>
      </div>` : ""}
      <div class="overflow-x-auto bg-white dark:bg-slate-900 p-4 space-y-3 max-h-96 overflow-y-auto">
        ${blocksHtml}
      </div>
    </div>
  `
}

function renderLoading(el) {
  el.innerHTML = `
    <div class="rounded-lg border border-slate-200 dark:border-slate-700 p-6">
      <div class="flex items-center gap-3 text-sm text-slate-500">
        <svg class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
        </svg>
        Running alignment...
      </div>
    </div>
  `
}

function renderError(el, message) {
  el.innerHTML = `
    <div class="rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 p-4">
      <p class="text-sm text-red-700 dark:text-red-400">${message}</p>
    </div>
  `
}

const AlignmentViewer = {
  async mounted() {
    try {
      await loadWasm()
    } catch (err) {
      renderError(this.el, `Failed to load WASM: ${err.message}`)
      return
    }

    // If pre-computed result is provided via data attribute
    const precomputed = this.el.dataset.result
    if (precomputed) {
      try {
        renderAlignment(this.el, JSON.parse(precomputed))
      } catch (err) {
        renderError(this.el, `Invalid alignment result: ${err.message}`)
      }
      return
    }

    // If query/target provided, run alignment on mount
    const query = this.el.dataset.query
    const target = this.el.dataset.target
    const mode = this.el.dataset.mode || "global"
    if (query && target) {
      this._runAlignment(query, target, mode)
    }

    // Listen for events from LiveView
    this.handleEvent("run-alignment", ({ query, target, mode, params }) => {
      this._runAlignment(query, target, mode || "global", params)
    })

    this.handleEvent("render-alignment", (result) => {
      renderAlignment(this.el, result)
    })
  },

  _runAlignment(query, target, mode, params) {
    renderLoading(this.el)

    try {
      let result
      if (params && params.matrix) {
        result = Align.alignProtein(query, target, mode, params.matrix)
      } else if (params && (params.match_score !== undefined)) {
        result = Align.alignDnaCustom(
          query, target, mode,
          params.match_score, params.mismatch_score,
          params.gap_open, params.gap_extend
        )
      } else {
        result = Align.alignDna(query, target, mode)
      }
      renderAlignment(this.el, result)
      this.pushEvent("alignment-complete", {
        score: result.score,
        query_start: result.query_start,
        query_end: result.query_end,
        target_start: result.target_start,
        target_end: result.target_end,
      })
    } catch (err) {
      renderError(this.el, `Alignment failed: ${err.message}`)
    }
  },

  updated() {
    const query = this.el.dataset.query
    const target = this.el.dataset.target
    const mode = this.el.dataset.mode || "global"
    if (query && target) {
      this._runAlignment(query, target, mode)
    }
  }
}

export default AlignmentViewer

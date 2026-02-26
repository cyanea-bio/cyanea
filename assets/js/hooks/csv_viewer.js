// CSV Viewer hook — sortable columns with client-side sort
const CsvViewer = {
  mounted() {
    this.columns = JSON.parse(this.el.dataset.columns || "[]")
    this.rows = JSON.parse(this.el.dataset.rows || "[]")
    this.sortCol = null
    this.sortAsc = true

    this.el.querySelectorAll("thead th").forEach((th, idx) => {
      th.addEventListener("click", () => this.sortByColumn(idx))
    })
  },

  sortByColumn(colIdx) {
    if (this.sortCol === colIdx) {
      this.sortAsc = !this.sortAsc
    } else {
      this.sortCol = colIdx
      this.sortAsc = true
    }

    const sorted = [...this.rows].sort((a, b) => {
      const valA = a[colIdx] || ""
      const valB = b[colIdx] || ""

      // Try numeric comparison
      const numA = parseFloat(valA)
      const numB = parseFloat(valB)
      if (!isNaN(numA) && !isNaN(numB)) {
        return this.sortAsc ? numA - numB : numB - numA
      }

      // String comparison
      return this.sortAsc
        ? valA.localeCompare(valB)
        : valB.localeCompare(valA)
    })

    // Re-render tbody
    const tbody = this.el.querySelector("tbody")
    if (!tbody) return

    tbody.innerHTML = sorted.map(row =>
      `<tr class="border-b border-slate-100 last:border-0 dark:border-slate-700/50">${
        row.map(cell =>
          `<td class="whitespace-nowrap px-3 py-1.5 text-xs text-slate-700 dark:text-slate-300">${this.escapeHtml(cell)}</td>`
        ).join("")
      }</tr>`
    ).join("")

    // Update header indicators
    this.el.querySelectorAll("thead th").forEach((th, idx) => {
      const arrow = idx === this.sortCol ? (this.sortAsc ? " \u2191" : " \u2193") : ""
      th.textContent = this.columns[idx] + arrow
    })
  },

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text || ""
    return div.innerHTML
  }
}

export default CsvViewer

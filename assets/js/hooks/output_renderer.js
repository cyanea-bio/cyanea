// OutputRenderer hook — renders cell execution output inline.
//
// Reads a JSON-encoded output from the data-output attribute,
// parses it, and renders the appropriate visualization.

import { renderOutput } from "../output_renderers.js"

const OutputRenderer = {
  mounted() {
    this._render()
  },

  updated() {
    this._render()
  },

  _render() {
    const raw = this.el.dataset.output
    if (!raw) {
      this.el.innerHTML = ""
      return
    }
    try {
      const output = JSON.parse(raw)
      this.el.innerHTML = renderOutput(output)
    } catch (err) {
      this.el.innerHTML = `<div class="text-sm text-red-500">Failed to render output: ${err.message}</div>`
    }
  },
}

export default OutputRenderer

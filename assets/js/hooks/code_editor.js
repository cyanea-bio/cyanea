// CodeMirror 6 LiveView hook for notebook code cells.
//
// Replaces <textarea> for code cells. Uses phx-update="ignore" so
// LiveView doesn't clobber the CodeMirror DOM.

import { EditorView, basicSetup } from "codemirror"
import { javascript } from "@codemirror/lang-javascript"
import { oneDark } from "@codemirror/theme-one-dark"
import { keymap } from "@codemirror/view"
import { EditorState } from "@codemirror/state"

function isDarkMode() {
  return document.documentElement.classList.contains("dark")
}

const CodeEditor = {
  mounted() {
    this._cellId = this.el.dataset.cellId
    this._updateTimer = null

    const source = this.el.dataset.source || ""

    const extensions = [
      basicSetup,
      javascript(),
      keymap.of([
        {
          key: "Shift-Enter",
          run: () => {
            this.pushEvent("run-cell", { "cell-id": this._cellId })
            return true
          },
        },
      ]),
      EditorView.updateListener.of((update) => {
        if (update.docChanged) {
          this._scheduleUpdate()
        }
      }),
      EditorView.theme({
        "&": { fontSize: "14px" },
        ".cm-content": { fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace" },
        ".cm-gutters": { borderRight: "none" },
      }),
    ]

    if (isDarkMode()) {
      extensions.push(oneDark)
    }

    this._view = new EditorView({
      state: EditorState.create({ doc: source, extensions }),
      parent: this.el,
    })
  },

  _scheduleUpdate() {
    if (this._updateTimer) clearTimeout(this._updateTimer)
    this._updateTimer = setTimeout(() => {
      const source = this._view.state.doc.toString()
      this.pushEvent("update-cell", {
        "cell-id": this._cellId,
        source,
      })
    }, 500)
  },

  destroyed() {
    if (this._updateTimer) clearTimeout(this._updateTimer)
    if (this._view) this._view.destroy()
  },
}

export default CodeEditor

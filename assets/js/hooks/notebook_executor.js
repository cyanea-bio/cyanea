// NotebookExecutor — orchestration hook for notebook cell execution.
//
// Manages the Web Worker lifecycle, execution context (variable store),
// cell queuing, timeouts, and auto-save. Attached to the notebook
// container div, replacing the AutoSave hook on that element.

import workerSource from "../notebook_worker.js?raw"

const CELL_TIMEOUT_MS = 30_000

const NotebookExecutor = {
  mounted() {
    this._context = [] // serialized Map entries for variable store
    this._worker = null
    this._timeoutId = null
    this._queue = [] // for run-all sequential execution
    this._running = false
    this._autoSaveTimer = null

    this._spawnWorker()

    // Listen for execute-cell events from LiveView
    this.handleEvent("execute-cell", ({ cell_id, source }) => {
      this._executeCell(cell_id, source)
    })

    // Listen for execute-all events from LiveView
    this.handleEvent("execute-all", ({ cells }) => {
      this._executeAll(cells)
    })

    // Auto-save: debounce input/change events
    this.el.addEventListener("input", () => this._scheduleAutoSave())
    this.el.addEventListener("change", () => this._scheduleAutoSave())

    this.handleEvent("auto-save-done", () => {
      this._autoSaving = false
    })
  },

  _spawnWorker() {
    if (this._worker) {
      this._worker.terminate()
    }

    const blob = new Blob([workerSource], { type: "application/javascript" })
    const url = URL.createObjectURL(blob)
    this._worker = new Worker(url, { type: "module" })
    URL.revokeObjectURL(url)

    this._worker.onmessage = (e) => {
      this._clearTimeout()

      if (e.data.type === "result") {
        // Update shared context
        this._context = e.data.context || []

        this.pushEvent("cell-result", {
          "cell-id": e.data.cellId,
          output: e.data.output,
        })
      } else if (e.data.type === "error") {
        this.pushEvent("cell-result", {
          "cell-id": e.data.cellId,
          output: {
            type: "error",
            data: e.data.message,
            timing_ms: 0,
          },
        })
      }

      this._running = false
      this._processQueue()
    }

    this._worker.onerror = (err) => {
      this._clearTimeout()
      this._running = false
      this._processQueue()
    }
  },

  _executeCell(cellId, source) {
    if (this._running) {
      this._queue.push({ cellId, source })
      return
    }

    this._running = true
    this._startTimeout(cellId)
    this._worker.postMessage({
      type: "execute",
      cellId,
      code: source,
      context: this._context,
    })
  },

  _executeAll(cells) {
    // Reset context for fresh run-all
    this._context = []
    this._queue = cells.map((c) => ({ cellId: c.id, source: c.source }))
    this._processQueue()
  },

  _processQueue() {
    if (this._queue.length === 0) return
    const next = this._queue.shift()
    this._executeCell(next.cellId, next.source)
  },

  _startTimeout(cellId) {
    this._clearTimeout()
    this._timeoutId = setTimeout(() => {
      // Terminate and respawn the worker
      this._spawnWorker()
      this._running = false

      this.pushEvent("cell-result", {
        "cell-id": cellId,
        output: {
          type: "error",
          data: "Execution timed out (30 seconds)",
          timing_ms: CELL_TIMEOUT_MS,
        },
      })

      this._processQueue()
    }, CELL_TIMEOUT_MS)
  },

  _clearTimeout() {
    if (this._timeoutId) {
      clearTimeout(this._timeoutId)
      this._timeoutId = null
    }
  },

  _scheduleAutoSave() {
    if (this._autoSaveTimer) clearTimeout(this._autoSaveTimer)
    this._autoSaveTimer = setTimeout(() => {
      if (!this._autoSaving) {
        this._autoSaving = true
        this.pushEvent("auto-save", {})
      }
    }, 2000)
  },

  destroyed() {
    this._clearTimeout()
    if (this._autoSaveTimer) clearTimeout(this._autoSaveTimer)
    if (this._worker) this._worker.terminate()
  },
}

export default NotebookExecutor

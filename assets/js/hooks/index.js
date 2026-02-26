// Hook registry -- re-exports all LiveView hooks.

import SequenceViewer from "./sequence_viewer.js"
import AlignmentViewer from "./alignment_viewer.js"
import TreeViewer from "./tree_viewer.js"
import AutoSave from "./auto_save.js"
import CodeEditor from "./code_editor.js"
import NotebookExecutor from "./notebook_executor.js"
import OutputRenderer from "./output_renderer.js"
import CsvViewer from "./csv_viewer.js"
import ImageViewer from "./image_viewer.js"
import MarkdownViewer from "./markdown_viewer.js"

// Command palette keyboard shortcut
const CommandPalette = {
  mounted() {
    document.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault()
        this.pushEvent("open-command-palette", {})
      }
    })
  }
}

// Dark mode toggle
const DarkMode = {
  mounted() {
    const darkModeMediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    const savedTheme = localStorage.getItem("theme")

    const setTheme = (theme) => {
      if (theme === "dark") {
        document.documentElement.classList.add("dark")
      } else {
        document.documentElement.classList.remove("dark")
      }
    }

    if (savedTheme) {
      setTheme(savedTheme)
    } else if (darkModeMediaQuery.matches) {
      setTheme("dark")
    }

    this.handleEvent("toggle-dark-mode", () => {
      const isDark = document.documentElement.classList.toggle("dark")
      localStorage.setItem("theme", isDark ? "dark" : "light")
    })
  }
}

// Copy to clipboard
const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.copyText
      navigator.clipboard.writeText(text).then(() => {
        this.el.dataset.copied = "true"
        setTimeout(() => { this.el.dataset.copied = "false" }, 2000)
      })
    })
  }
}

// File upload with progress
const FileUpload = {
  mounted() {
    this.el.addEventListener("change", (e) => {
      const files = e.target.files
      if (files.length > 0) {
        this.pushEvent("files-selected", {
          files: Array.from(files).map(f => ({
            name: f.name,
            size: f.size,
            type: f.type
          }))
        })
      }
    })
  }
}

export const Hooks = {
  CommandPalette,
  DarkMode,
  CopyToClipboard,
  FileUpload,
  SequenceViewer,
  AlignmentViewer,
  TreeViewer,
  AutoSave,
  CodeEditor,
  NotebookExecutor,
  OutputRenderer,
  CsvViewer,
  ImageViewer,
  MarkdownViewer,
}

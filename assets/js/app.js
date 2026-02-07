// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Hooks
let Hooks = {}

// Command palette keyboard shortcut
Hooks.CommandPalette = {
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
Hooks.DarkMode = {
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

// File upload with progress
Hooks.FileUpload = {
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

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#06B6D4"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

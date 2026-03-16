// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {Hooks} from "./hooks/index.js"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

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

// Expose WASM API on window for interactive testing in the browser console:
// >> await cyanea.ready
// >> cyanea.Seq.gcContent("ATGCGCTA")
// >> cyanea.Align.alignDna("ACGT", "ACTT", "global")
// >> cyanea.Phylo.newickInfo("((A:0.1,B:0.2):0.3,C:0.4);")
import {loadWasm, Seq, Align, Phylo, Stats, ML, Chem, StructBio, IO, Omics, Core} from "./wasm.js"
window.cyanea = { ready: loadWasm(), Seq, Align, Phylo, Stats, ML, Chem, StructBio, IO, Omics, Core }

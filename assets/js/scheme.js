// Colour scheme: System (follows the OS), Light or Dark.
// The choice is stored as localStorage "theme" ("light" | "dark"; absent = system);
// an inline script in root.html.heex applies it before first paint.
const KEY = "theme"
const root = document.documentElement
const media = window.matchMedia("(prefers-color-scheme: dark)")

function stored() {
  try {
    const v = localStorage.getItem(KEY)
    return v === "light" || v === "dark" ? v : "system"
  } catch (e) {
    return "system"
  }
}

function apply() {
  const s = stored()
  root.classList.toggle("dark", s === "dark" || (s === "system" && media.matches))
}

function paint() {
  const s = stored()
  document.querySelectorAll("[data-scheme]").forEach((b) => {
    b.setAttribute("aria-pressed", String(b.dataset.scheme === s))
  })
}

export function initScheme() {
  media.addEventListener("change", apply)
  document.addEventListener("click", (e) => {
    const b = e.target.closest("[data-scheme]")
    if (!b) return
    try {
      if (b.dataset.scheme === "system") localStorage.removeItem(KEY)
      else localStorage.setItem(KEY, b.dataset.scheme)
    } catch (err) {}
    apply()
    paint()
  })
  // LiveView navigation re-renders the footer
  window.addEventListener("phx:page-loading-stop", paint)
  apply()
  paint()
}

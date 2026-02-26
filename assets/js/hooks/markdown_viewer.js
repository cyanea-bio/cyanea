// Markdown Viewer hook — renders KaTeX math blocks
const MarkdownViewer = {
  mounted() {
    this.renderMath()
  },

  updated() {
    this.renderMath()
  },

  async renderMath() {
    // Find math blocks: $...$ (inline) and $$...$$ (display)
    const mathElements = this.el.querySelectorAll("code")
    const hasMath = Array.from(mathElements).some(el => {
      const text = el.textContent
      return text.match(/^\$.*\$$/) || text.match(/^\$\$.*\$\$$/)
    })

    // Also check raw text for math delimiters
    const rawText = this.el.textContent
    const hasInlineMath = rawText.includes("$") && !hasMath

    if (!hasMath && !hasInlineMath) return

    try {
      // Load KaTeX from CDN if not already loaded
      if (!window.katex) {
        await this.loadKaTeX()
      }

      if (window.katex) {
        this.renderKaTeXInElement(this.el)
      }
    } catch (e) {
      console.warn("KaTeX rendering failed:", e)
    }
  },

  loadKaTeX() {
    return new Promise((resolve, reject) => {
      if (window.katex) { resolve(); return }

      // Load CSS
      const link = document.createElement("link")
      link.rel = "stylesheet"
      link.href = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"
      document.head.appendChild(link)

      // Load JS
      const script = document.createElement("script")
      script.src = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  },

  renderKaTeXInElement(el) {
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null)
    const textNodes = []
    while (walker.nextNode()) textNodes.push(walker.currentNode)

    textNodes.forEach(node => {
      const text = node.textContent

      // Display math: $$...$$
      const displayRegex = /\$\$([\s\S]+?)\$\$/g
      // Inline math: $...$
      const inlineRegex = /\$([^\$\n]+?)\$/g

      if (!displayRegex.test(text) && !inlineRegex.test(text)) return

      const span = document.createElement("span")
      let result = text

      // Replace display math first
      result = result.replace(/\$\$([\s\S]+?)\$\$/g, (_, math) => {
        try {
          return window.katex.renderToString(math, { displayMode: true, throwOnError: false })
        } catch { return `$$${math}$$` }
      })

      // Replace inline math
      result = result.replace(/\$([^\$\n]+?)\$/g, (_, math) => {
        try {
          return window.katex.renderToString(math, { displayMode: false, throwOnError: false })
        } catch { return `$${math}$` }
      })

      if (result !== text) {
        span.innerHTML = result
        node.parentNode.replaceChild(span, node)
      }
    })
  }
}

export default MarkdownViewer

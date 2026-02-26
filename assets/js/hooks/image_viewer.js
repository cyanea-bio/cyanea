// Image Viewer hook — zoom (scroll wheel), pan (drag), reset
const ImageViewer = {
  mounted() {
    this.scale = 1
    this.translateX = 0
    this.translateY = 0
    this.isDragging = false
    this.startX = 0
    this.startY = 0

    this.image = this.el.querySelector("[data-image]")
    this.container = this.el.querySelector("[data-image-container]")
    if (!this.image || !this.container) return

    // Zoom with scroll wheel
    this.container.addEventListener("wheel", (e) => {
      e.preventDefault()
      const delta = e.deltaY > 0 ? -0.1 : 0.1
      this.scale = Math.max(0.1, Math.min(10, this.scale + delta))
      this.applyTransform()
    }, { passive: false })

    // Pan with drag
    this.container.addEventListener("mousedown", (e) => {
      if (this.scale <= 1) return
      this.isDragging = true
      this.startX = e.clientX - this.translateX
      this.startY = e.clientY - this.translateY
      this.container.style.cursor = "grabbing"
    })

    document.addEventListener("mousemove", (e) => {
      if (!this.isDragging) return
      this.translateX = e.clientX - this.startX
      this.translateY = e.clientY - this.startY
      this.applyTransform()
    })

    document.addEventListener("mouseup", () => {
      this.isDragging = false
      if (this.container) this.container.style.cursor = this.scale > 1 ? "grab" : "default"
    })

    // Button controls
    this.el.querySelector("[data-action='zoom-in']")?.addEventListener("click", () => {
      this.scale = Math.min(10, this.scale + 0.25)
      this.applyTransform()
    })

    this.el.querySelector("[data-action='zoom-out']")?.addEventListener("click", () => {
      this.scale = Math.max(0.1, this.scale - 0.25)
      this.applyTransform()
    })

    this.el.querySelector("[data-action='zoom-reset']")?.addEventListener("click", () => {
      this.scale = 1
      this.translateX = 0
      this.translateY = 0
      this.applyTransform()
    })
  },

  applyTransform() {
    if (!this.image) return
    this.image.style.transform = `translate(${this.translateX}px, ${this.translateY}px) scale(${this.scale})`
  }
}

export default ImageViewer

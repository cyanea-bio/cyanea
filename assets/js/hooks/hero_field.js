// A field of light points on a slowly moving surface, seen in perspective:
// the same calm, monochrome background as the cyanea.bio hero. Pauses off
// screen and in hidden tabs; draws one still frame for reduced motion.
const HeroField = {
  mounted() {
    const canvas = this.el
    const ctx = canvas.getContext("2d")
    const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const COLS = 120, ROWS = 44, NEAR = 1.2, FAR = 10, SPAN = 8, CAM = 0.9
    let w = 0, h = 0, raf = 0, visible = true
    const t0 = performance.now()

    const size = () => {
      const r = canvas.getBoundingClientRect()
      const dpr = Math.min(window.devicePixelRatio || 1, 2)
      w = r.width
      h = r.height
      canvas.width = Math.round(w * dpr)
      canvas.height = Math.round(h * dpr)
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    }

    const height = (x, z, t) =>
      0.22 * Math.sin(x * 0.9 + t * 0.22) +
      0.16 * Math.sin(z * 1.3 - t * 0.17) +
      0.09 * Math.sin((x + z) * 1.9 + t * 0.31) +
      0.05 * Math.sin((x - z) * 3.1 - t * 0.26)

    // Faint behind the copy on the left, full from 70% across
    const fade = (u) => {
      if (w < 768) return 0.7
      const k = Math.min(1, Math.max(0, (u - 0.3) / 0.4))
      return 0.12 + 0.88 * k * k * (3 - 2 * k)
    }

    const draw = (now) => {
      const t = (now - t0) / 1000
      ctx.clearRect(0, 0, w, h)
      const f = h * 0.8, cx = w * 0.62, horizon = h * 0.45
      ctx.save()
      ctx.translate(cx, horizon + h * 0.06)
      ctx.scale(1, 0.18)
      const g = ctx.createRadialGradient(0, 0, 0, 0, 0, w * 0.45)
      g.addColorStop(0, "rgba(195, 179, 255, 0.16)")
      g.addColorStop(1, "rgba(195, 179, 255, 0)")
      ctx.fillStyle = g
      ctx.fillRect(-w, -w * 0.5, w * 2, w)
      ctx.restore()
      for (let j = 0; j < ROWS; j++) {
        const z = FAR - (FAR - NEAR) * (j / (ROWS - 1))
        const depth = 1 - (z - NEAR) / (FAR - NEAR)
        for (let i = 0; i < COLS; i++) {
          const x = (i / (COLS - 1) - 0.5) * SPAN * 2
          const y = height(x, z, t)
          const sx = cx + (x * f) / z
          if (sx < -4 || sx > w + 4) continue
          const sy = horizon + ((CAM - y) * f) / z
          if (sy > h + 4) continue
          if (w < 768 && sy < h * 0.7) continue
          const crest = Math.max(0, y) / 0.5
          const a = (0.14 + 0.62 * Math.pow(depth, 1.5)) * (0.5 + 0.5 * crest) * fade(sx / w)
          const s = 0.8 + 1.7 * depth
          ctx.fillStyle = `rgba(214, 205, 255, ${a.toFixed(3)})`
          ctx.fillRect(sx - s / 2, sy - s / 2, s, s)
        }
      }
    }

    const loop = (now) => {
      draw(now)
      raf = visible && !document.hidden ? requestAnimationFrame(loop) : 0
    }
    const start = () => { if (!raf && !still) raf = requestAnimationFrame(loop) }

    size()
    draw(still ? t0 + 4000 : performance.now())
    this.resize = new ResizeObserver(() => { size(); draw(still ? t0 + 4000 : performance.now()) })
    this.resize.observe(canvas)
    if (still) return
    this.io = new IntersectionObserver((entries) => { visible = entries[0].isIntersecting; if (visible) start() })
    this.io.observe(canvas)
    this.onVisible = () => { if (!document.hidden) start() }
    document.addEventListener("visibilitychange", this.onVisible)
    this.stop = () => { cancelAnimationFrame(raf); raf = 0 }
    start()
  },
  destroyed() {
    this.resize && this.resize.disconnect()
    this.io && this.io.disconnect()
    this.onVisible && document.removeEventListener("visibilitychange", this.onVisible)
    this.stop && this.stop()
  }
}

export default HeroField

import { Controller } from "@hotwired/stimulus"

// Snap-scroll shelf with prev/next chevrons. Direction-agnostic so it works
// in both LTR and RTL: boundary checks use Math.abs(scrollLeft).
export default class extends Controller {
  static targets = ["track", "prev", "next"]

  connect() {
    this.scheduled = false
    this.onScroll = this.onScroll.bind(this)
    this.trackTarget.addEventListener("scroll", this.onScroll, { passive: true })

    if (typeof ResizeObserver !== "undefined") {
      this.observer = new ResizeObserver(() => this.update())
      this.observer.observe(this.trackTarget)
    }

    this.update()
  }

  disconnect() {
    this.trackTarget.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
  }

  prev() {
    this.trackTarget.scrollBy({ left: -this.step(), behavior: "smooth" })
  }

  next() {
    this.trackTarget.scrollBy({ left: this.step(), behavior: "smooth" })
  }

  onScroll() {
    if (this.scheduled) return
    this.scheduled = true
    requestAnimationFrame(() => {
      this.scheduled = false
      this.update()
    })
  }

  update() {
    const el = this.trackTarget
    const max = el.scrollWidth - el.clientWidth
    const pos = Math.abs(el.scrollLeft)
    const scrollable = max > 1
    const atStart = !scrollable || pos < 4
    const atEnd = !scrollable || pos > max - 4
    this.setVisible(this.hasPrevTarget && this.prevTarget, !atStart)
    this.setVisible(this.hasNextTarget && this.nextTarget, !atEnd)
  }

  setVisible(el, visible) {
    if (!el) return
    el.classList.toggle("opacity-0", !visible)
    el.classList.toggle("pointer-events-none", !visible)
    if (visible) {
      el.removeAttribute("aria-hidden")
      el.removeAttribute("disabled")
    } else {
      el.setAttribute("aria-hidden", "true")
      el.setAttribute("disabled", "true")
    }
  }

  step() {
    return Math.max(this.trackTarget.clientWidth * 0.85, 240)
  }
}

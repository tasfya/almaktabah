import { Controller } from "@hotwired/stimulus"

// Swaps an <img> whose source fails to load for a fallback image.
export default class extends Controller {
  static values = { src: String }

  connect() {
    this.fallback = this.fallback.bind(this)
    this.element.addEventListener("error", this.fallback)
    // The image may have failed before this controller connected.
    if (this.element.complete && this.element.naturalWidth === 0) this.fallback()
  }

  disconnect() {
    this.element.removeEventListener("error", this.fallback)
  }

  fallback() {
    if (!this.hasSrcValue || this.element.getAttribute("src") === this.srcValue) return

    this.element.removeAttribute("srcset")
    this.element.src = this.srcValue
  }
}

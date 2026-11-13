import { Controller } from "@hotwired/stimulus"

// Shows the site's name in place of its logo when the logo fails to load,
// rather than any other site's artwork.
export default class extends Controller {
  static targets = ["image", "name"]

  connect() {
    this.fallback = this.fallback.bind(this)
    this.imageTarget.addEventListener("error", this.fallback)
    // The image may have failed before this controller connected.
    if (this.imageTarget.complete && this.imageTarget.naturalWidth === 0) this.fallback()
  }

  disconnect() {
    this.imageTarget.removeEventListener("error", this.fallback)
  }

  fallback() {
    this.imageTarget.hidden = true
    this.nameTarget.hidden = false
  }
}

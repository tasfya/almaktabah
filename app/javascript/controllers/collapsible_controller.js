import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "minimizeIcon", "maximizeIcon", "toggleButton"]

  connect() {
    this.isCollapsed = true
    this.collapse()
  }

  toggle() {
    if (this.isCollapsed) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  collapse() {
    this.contentTarget.classList.add("hidden")
    this.minimizeIconTarget.classList.add("hidden")
    this.maximizeIconTarget.classList.remove("hidden")
    this.isCollapsed = true
  }

  expand() {
    this.contentTarget.classList.remove("hidden")
    this.minimizeIconTarget.classList.remove("hidden")
    this.maximizeIconTarget.classList.add("hidden")
    this.isCollapsed = false
  }
}
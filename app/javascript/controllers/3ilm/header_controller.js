import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="3ilm--header"
export default class extends Controller {
  static targets = ["header"]

  connect() {
    this.lastScroll = 0
    this.header = this.headerTarget
    window.addEventListener("scroll", this.onScroll.bind(this))
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll.bind(this))
  }

  onScroll() {
    const currentScroll = window.pageYOffset || document.documentElement.scrollTop

    if (currentScroll > this.lastScroll && currentScroll > 50) {
      // Scrolling down
      this.header.style.transform = "translateY(-100%)"
    } else {
      // Scrolling up
      this.header.style.transform = "translateY(0)"
    }

    this.lastScroll = currentScroll
  }
}

import { Controller } from "@hotwired/stimulus"

const SHOWN_WITHIN = 24 * 60 * 60
const SHORT_WITHIN = 10 * 60

// Time left before an exam closes, shown in its last day. Counts from the
// server's clock (the offset to the device clock is taken once), so a wrong
// device clock does not move a strict deadline.
export default class extends Controller {
  static values = { closesAt: Number, now: Number, template: String, shortTemplate: String, up: String }

  connect() {
    this.offset = this.nowValue - Date.now()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const left = Math.max(0, Math.floor((this.closesAtValue - (Date.now() + this.offset)) / 1000))
    this.element.hidden = left > SHOWN_WITHIN
    const short = left < SHORT_WITHIN
    this.element.classList.toggle("text-red-700", short)
    this.element.classList.toggle("font-semibold", short)

    if (left === 0) {
      this.element.textContent = this.upValue
      clearInterval(this.timer)
    } else {
      this.element.textContent = (short ? this.shortTemplateValue : this.templateValue).replace("%{time}", this.format(left))
    }
  }

  format(seconds) {
    const hours = Math.floor(seconds / 3600)
    const minutes = String(Math.floor((seconds % 3600) / 60)).padStart(2, "0")
    const rest = String(seconds % 60).padStart(2, "0")
    return `${hours}:${minutes}:${rest}`
  }
}

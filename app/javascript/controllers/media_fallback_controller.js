import { Controller } from "@hotwired/stimulus"

// Hides an <audio>/<video> whose source fails to load and shows a notice instead.
// The error fires on the <source> child when there is one; error events do not
// bubble, so the listener runs in the capture phase.
export default class extends Controller {
  static targets = ["media", "notice"]

  connect() {
    this.failed = this.failed.bind(this)
    this.reset = this.reset.bind(this)
    this.element.addEventListener("error", this.failed, true)
    this.element.addEventListener("loadstart", this.reset, true)
    if (this.hasMediaTarget && this.mediaTarget.networkState === HTMLMediaElement.NETWORK_NO_SOURCE) this.failed()
  }

  disconnect() {
    this.element.removeEventListener("error", this.failed, true)
    this.element.removeEventListener("loadstart", this.reset, true)
  }

  failed(event) {
    if (!this.hasMediaTarget) return
    if (event && !this.mediaTarget.contains(event.target)) return

    this.mediaTarget.pause?.()
    this.mediaTarget.hidden = true
    if (this.hasNoticeTarget) this.noticeTarget.hidden = false
  }

  reset() {
    this.mediaTarget.hidden = false
    if (this.hasNoticeTarget) this.noticeTarget.hidden = true
  }
}

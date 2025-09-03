import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { modalId: String }

  open() {
    const modal = document.getElementById(this.modalIdValue)
    if (modal) {
      modal.showModal()
    }
  }
}

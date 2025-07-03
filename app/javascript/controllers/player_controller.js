import ApplicationController from "./application_controller"

export default class extends ApplicationController {
  play() {
    this.element.play()
  }

  toggle() {
    if (this.element.paused) this.play()
    else this.element.pause()
  }
}

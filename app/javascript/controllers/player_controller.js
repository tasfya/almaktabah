import ApplicationController from "controllers/application_controller"

export default class extends ApplicationController {
  play() {
    this.element.play()
  }

  connect() {
    console.log("Connected")
  }

  toggle() {
    if (this.element.paused) this.play()
    else this.element.pause()
  }
}
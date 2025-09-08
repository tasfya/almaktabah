import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, title: String }

  connect() {
    console.log("YouTube button controller connected")
  }

  play() {
    console.log("YouTube button clicked")
    
    const floatingVideoPlayer = document.querySelector('[data-controller*="floating-video"]')
    if (!floatingVideoPlayer) {
      console.error("Floating video player not found")
      return
    }

    const controller = this.application.getControllerForElementAndIdentifier(
      floatingVideoPlayer, 
      "floating-video"
    )
    
    if (controller) {
      controller.loadYouTubeVideo(this.urlValue, this.titleValue)
    } else {
      console.error("Floating video controller not found")
    }
  }
}

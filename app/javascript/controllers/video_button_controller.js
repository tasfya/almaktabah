import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    url: String,
    type: String,
    title: String
  }

  connect() {
    console.log("Video button controller connected")
  }

  play() {
    console.log("Play button clicked for:", this.titleValue)
    const floatingPlayer = document.getElementById('floating-video-player')
    
    if (floatingPlayer) {
      const controller = this.application.getControllerForElementAndIdentifier(floatingPlayer, 'floating-video')
      
      if (controller) {
        controller.loadVideo(this.urlValue, this.typeValue, this.titleValue)
      } else {
        console.error("Could not find floating video controller")
      }
    } else {
      console.error("Could not find floating video player")
    }
  }
}

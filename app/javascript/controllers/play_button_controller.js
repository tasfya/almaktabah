import ApplicationController from "controllers/application_controller"

export default class extends ApplicationController {
  static outlets = ["player"]
  static targets = ["button", "icon", "loadingIcon", "text", "template"]

  playerOutletConnected(controller, element) {
    element.addEventListener("play", this.#press)
    element.addEventListener("pause", this.#unpress)
    element.addEventListener("ended", this.#unpress)

    element.setAttribute("aria-controls", element.id)

    if (element.paused) this.#unpress()
    else this.#press()
  }

  playerOutletDisconnected(controller, element) {
    element.removeEventListener("play", this.#press)
    element.removeEventListener("pause", this.#unpress)
    element.removeEventListener("ended", this.#unpress)

    element.removeAttribute("aria-controls")
    this.#unpress()
  }

  handleSubmit(event) {
    // Stop any currently playing audio
    this.stopCurrentAudio()
    
    // Show loading state
    this.showLoading()
    
    // Show loading in audio player area
    this.showAudioPlayerLoading()
    
    // The form submission will continue normally after this
  }

  stopCurrentAudio() {
    // Find any currently playing audio elements and pause them
    const audioElements = document.querySelectorAll("audio")
    audioElements.forEach(audio => {
      if (!audio.paused) {
        audio.pause()
      }
    })

    // Also clear the current audio player if it exists
    const audioPlayer = document.getElementById("audio-player")
    if (audioPlayer && audioPlayer.innerHTML.trim() !== "") {
      // Send a request to stop the current player
      fetch("/play/stop", {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        }
      }).then(response => {
        if (response.ok) {
          return response.text()
        }
      }).then(html => {
        if (html) {
          Turbo.renderStreamMessage(html)
        }
      }).catch(error => {
        console.error("Error stopping audio:", error)
      })
    }
  }

  showLoading() {
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("hidden")
    }
    if (this.hasLoadingIconTarget) {
      this.loadingIconTarget.classList.remove("hidden")
    }
    if (this.hasTextTarget) {
      this.textTarget.textContent = this.textTarget.dataset.loadingText || "جاري التحميل..."
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
  }

  showAudioPlayerLoading() {
    const audioPlayer = document.getElementById("audio-player")
    
    if (audioPlayer && this.hasTemplateTarget) {
      // Clone the template content
      const template = this.templateTarget
      const clone = template.content.cloneNode(true)
      
      // Clear the audio player and add the cloned template
      audioPlayer.innerHTML = ""
      audioPlayer.appendChild(clone)
    }
  }

  hideLoading() {
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("hidden")
    }
    if (this.hasLoadingIconTarget) {
      this.loadingIconTarget.classList.add("hidden")
    }
    if (this.hasTextTarget) {
      this.textTarget.textContent = this.data.get("originalText") || "Listen"
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
    }
  }

  toggle() {
    for (const playerOutlet of this.playerOutlets) {
      playerOutlet.toggle()
    }
  }

  connect() {
    // Store the original text
    if (this.hasTextTarget) {
      this.data.set("originalText", this.textTarget.textContent)
    }

    // Listen for turbo:submit-end to hide loading state
    this.element.addEventListener("turbo:submit-end", this.hideLoading.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.hideLoading.bind(this))
  }

  #press = () => {
    this.element.setAttribute("aria-pressed", true)
  }

  #unpress = () => {
    this.element.setAttribute("aria-pressed", false)
  }
}

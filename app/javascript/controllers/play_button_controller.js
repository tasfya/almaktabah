import ApplicationController from "controllers/application_controller"

export default class extends ApplicationController {
  static outlets = ["player"]
  static targets = [
    "button", "playIcon", "pauseIcon", "loadingIcon", "text", "template"
  ]

  connect() {
    if (this.hasTextTarget) {
      this.data.set("originalText", this.textTarget.textContent)
    }
    this.element.addEventListener("audio:playing", this.hideLoading.bind(this))
    this.element.addEventListener("audio:playing", this.#toggleAudioIcons.bind(this, true))
    this.element.addEventListener("audio:paused", this.#toggleAudioIcons.bind(this, false))
    const currentlyPlaying = this.element.dataset.currentlyPlaying === "true"
    this.#toggleAudioIcons(currentlyPlaying)

  }

  disconnect() {
    this.element.removeEventListener("audio:playing", this.hideLoading.bind(this))
    this.element.removeEventListener("audio:playing", this.#toggleAudioIcons.bind(this, true))
    this.element.removeEventListener("audio:paused", this.#toggleAudioIcons.bind(this, false))

  }

  // Called when a player outlet is connected
  playerOutletConnected(controller, element) {
    element.addEventListener("play", this.#press)
    element.addEventListener("pause", this.#unpress)
    element.addEventListener("ended", this.#unpress)

    element.setAttribute("aria-controls", element.id)

    element.paused ? this.#unpress() : this.#press()
  }

  playerOutletDisconnected(controller, element) {
    element.removeEventListener("play", this.#press)
    element.removeEventListener("pause", this.#unpress)
    element.removeEventListener("ended", this.#unpress)

    element.removeAttribute("aria-controls")
    this.#unpress()
  }

  handleSubmit(event) {
    this.clearOtherPlayButtons()

    const currentlyPlaying = event.target.dataset.currentlyPlaying === "true"
    if (this.#isPlayerLoaded(event)) {
      console.log("Player is already loaded")
      event.preventDefault()
      currentlyPlaying ? this.#pauseAllAudio() : this.#playAudio()
      event.target.dataset.currentlyPlaying = (!currentlyPlaying).toString()
      this.#toggleAudioIcons(!currentlyPlaying)
      return
    }

    this.#stopCurrentAudio()
    this.#showLoading()
    this.#showAudioPlayerLoading()
    event.target.dataset.currentlyPlaying = "true"
  }

  clearOtherPlayButtons() {
    const playButtons = document.querySelectorAll("[data-controller='play-button']")
    playButtons.forEach(button => {
      if (button !== this.element) {
        const buttonEl = button.querySelector("button[data-play-button-target='button']")
        if (!buttonEl) return

        buttonEl.dataset.currentlyPlaying = "false"

        const playIcon = button.querySelector("[data-play-button-target='playIcon']")
        const pauseIcon = button.querySelector("[data-play-button-target='pauseIcon']")

        if (playIcon) playIcon.classList.remove("hidden")
        if (pauseIcon) pauseIcon.classList.add("hidden")
      }
    })
  }

  hideLoading() {
    if (this.hasPauseIconTarget) {
      this.playIconTarget.classList.add("hidden")
      this.pauseIconTarget.classList.remove("hidden")
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
    this.playerOutlets.forEach(player => player.toggle())
  }

  #press = () => {
    this.element.setAttribute("aria-pressed", "true")
  }

  #unpress = () => {
    this.element.setAttribute("aria-pressed", "false")
  }

  #isPlayerLoaded(event) {
    const playerId = event.target.dataset.playerId
    const exists = document.getElementById(playerId) !== null
    return exists
  }

  #pauseAllAudio() {
    document.querySelectorAll("audio").forEach(audio => {
      if (!audio.paused) audio.pause()
    })
  }

  #playAudio() {
    document.querySelectorAll("audio").forEach(audio => {
      if (audio.paused) {
        audio.play().catch(error => {
          console.error("Error playing audio:", error)
        })
      }
    })
  }

  #toggleAudioIcons(isPlaying) {
    if (this.hasPlayIconTarget) {
      this.playIconTarget.classList.toggle("hidden", isPlaying)
    }
    if (this.hasPauseIconTarget) {
      this.pauseIconTarget.classList.toggle("hidden", !isPlaying)
    }
  }

  #stopCurrentAudio() {
    document.querySelectorAll("audio").forEach(audio => {
      if (!audio.paused) audio.pause()
    })

    const audioPlayer = document.getElementById("audio-player")
    if (audioPlayer && audioPlayer.innerHTML.trim() !== "") {
      fetch("/play/stop", {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        }
      })
        .then(response => response.ok ? response.text() : null)
        .then(html => {
          if (html) Turbo.renderStreamMessage(html)
        })
        .catch(error => {
          console.error("Error stopping audio:", error)
        })
    }
  }

  #showLoading() {
    if (this.hasPlayIconTarget) this.playIconTarget.classList.add("hidden")
    if (this.hasLoadingIconTarget) this.loadingIconTarget.classList.remove("hidden")

    if (this.hasTextTarget) {
      this.textTarget.textContent = this.textTarget.dataset.loadingText || "جاري التحميل..."
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
  }

  #showAudioPlayerLoading() {
    const audioPlayer = document.getElementById("audio-player")
    if (audioPlayer && this.hasTemplateTarget) {
      const clone = this.templateTarget.content.cloneNode(true)
      audioPlayer.innerHTML = ""
      audioPlayer.appendChild(clone)
    }
  }
}

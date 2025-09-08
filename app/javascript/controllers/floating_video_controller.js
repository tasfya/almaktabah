import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "youtubeIframe", "title", "videoContainer", "minimizeBtn"]

  connect() {
    this.setupMobileOptimizations()
    this.isMinimized = false
  }

  setupMobileOptimizations() {
    this.adjustForMobile()
    window.addEventListener("orientationchange", () => {
      setTimeout(() => this.adjustForMobile(), 100)
    })
  }

  adjustForMobile() {
    if (window.innerWidth < 768 && window.innerWidth < 380) {
      this.element.classList.remove("w-80")
      this.element.classList.add("w-72")
    }
  }

  loadVideo(videoUrl, videoType, videoTitle) {

    this.youtubeIframeTarget.classList.add("hidden")
    this.youtubeIframeTarget.src = ""

    this.videoTarget.innerHTML = `<source src="${videoUrl}" type="${videoType}">`
    this.videoTarget.load()
    this.videoTarget.classList.remove("hidden")
    this.titleTarget.textContent = videoTitle

    this.show()
    if (window.innerWidth < 768) {
      this.showMobileControlsHint()
    }
  }

  loadYouTubeVideo(youtubeUrl, videoTitle) {
    this.videoTarget.pause?.()
    this.videoTarget.classList.add("hidden")

    this.youtubeIframeTarget.src = youtubeUrl
    this.youtubeIframeTarget.classList.remove("hidden")

    this.titleTarget.textContent = videoTitle
    this.show()

  }

  showMobileControlsHint() {
    const video = this.videoTarget
    video.classList.remove("hidden")
    video.setAttribute("controls", true)

    const playPromise = video.play()
    if (playPromise !== undefined) {
      playPromise.catch(() => {
        console.log("Auto-play prevented by browser policy")
      })
    }
  }

  toggleMinimize() {
    this.isMinimized ? this.maximize() : this.minimize()
  }

  minimize() {
    this.isMinimized = true
    this.videoContainerTarget.classList.add("hidden")
    this.element.classList.add("w-full", "md:w-48")
    this.element.classList.remove("w-72", "w-80", "md:w-96")

    this.minimizeBtnTarget.innerHTML = `
      <svg class="size-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
      </svg>
    `
  }

  maximize() {
    this.isMinimized = false
    this.videoContainerTarget.classList.remove("hidden")
    this.element.classList.remove("w-full", "md:w-48")
    this.element.classList.add("w-80", "md:w-96")

    this.minimizeBtnTarget.innerHTML = `
      <svg class="size-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 12H6"/>
      </svg>
    `

  }

  show() {
    console.log("Showing video player")
    this.element.classList.remove("hidden")
    this.adjustForMobile()

    if (this.isMinimized) {
      this.maximize()
    }
  }

  close() {
    this.element.classList.add("hidden")

    if (this.videoTarget.pause) {
      this.videoTarget.pause()
    }
    this.videoTarget.classList.add("hidden")
    this.youtubeIframeTarget.src = ""
    this.youtubeIframeTarget.classList.add("hidden")
  }

  isVisible() {
    return !this.element.classList.contains("hidden")
  }

  disconnect() {
    window.removeEventListener("orientationchange", this.adjustForMobile)
  }
}

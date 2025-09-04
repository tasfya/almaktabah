import ApplicationController from "controllers/application_controller"
// connects to data-controller="player"
export default class extends ApplicationController {
  static values = {
    title: String,
    artist: String,
    artwork: String,
    domain: String
  }

  connect() {
    console.log("Connected player controller")
    this.setupMediaSession()
    this.setupMediaSessionHandlers()
    this.play()
    this.setupUserInteractionListeners()
  }

  disconnect() {
    this.clearMediaSession()
  }

  setupUserInteractionListeners() {
    const playButton = document.querySelector(`[data-player-id='${this.element.id}_player_content']`)
    if (!playButton) {
      console.warn("Play button not found for player:", this.element.id)
      return
    }
    this.element.addEventListener("play", () => {
      const event = new Event("audio:playing")
      playButton.dispatchEvent(event)
      console.log("Dispatched audio:playing event")
    })

    this.element.addEventListener("pause", () => {
      const event = new Event("audio:paused")
      playButton.dispatchEvent(event)
      console.log("Dispatched audio:paused event")
    })
  }

  play() {
    const playPromise = this.element.play()
    console.log("play promise:", playPromise)

    if (playPromise !== undefined) {
      playPromise.then(() => {
        console.log("Playback started")
        // launch new event to notify play button controllers
        const event = new Event("audio:playing")
        const playButton = document.querySelector(`[data-player-id='${this.element.id}_player_content']`)
        playButton.dispatchEvent(event)
      }).catch(error => {
        console.warn("Playback failed:", error)
      })
    }
  }

  toggle() {
    if (this.element.paused) {
      this.play().then(() => {
        const event = new Event("audio:playing")
        console.log("Dispatching audio:playing event")
        const playButton = document.querySelector(`[data-player-id='${this.element.id}_player_content']`)
        playButton.dispatchEvent(event)
      })
    } else {
      this.element.pause().then(() => {
        const event = new Event("audio:paused")
        console.log("Dispatching audio:paused event")
        const playButton = document.querySelector(`[data-player-id='${this.element.id}_player_content']`)
        playButton.dispatchEvent(event)
      })
    }
  }

  setupMediaSession() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: this.titleValue || 'Audio',
        artist: this.artistValue || this.domainValue || 'مكتبة الشيخ',
        artwork: this.getArtworkArray()
      })

      navigator.mediaSession.playbackState = 'paused'
    }
  }

  getArtworkArray() {
    const artworks = []

    if (this.artworkValue) {
      artworks.push({
        src: this.artworkValue,
        sizes: '512x512',
        type: 'image/png'
      })
    }

    const faviconLink = document.querySelector('link[rel="apple-touch-icon"]')
    if (faviconLink) {
      artworks.push({
        src: faviconLink.href,
        sizes: '180x180',
        type: 'image/png'
      })
    }

    const faviconLinks = document.querySelectorAll('link[rel="apple-touch-icon"]')
    faviconLinks.forEach(link => {
      if (link.href && !artworks.some(a => a.src === link.href)) {
        artworks.push({
          src: link.href,
          sizes: link.getAttribute('sizes') || '180x180',
          type: 'image/png'
        })
      }
    })

    return artworks
  }

  setupMediaSessionHandlers() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.setActionHandler('play', () => {
        this.play()
        navigator.mediaSession.playbackState = 'playing'
      })

      navigator.mediaSession.setActionHandler('pause', () => {
        this.element.pause()
        navigator.mediaSession.playbackState = 'paused'
      })

      navigator.mediaSession.setActionHandler('seekto', (details) => {
        if (details.seekTime) {
          this.element.currentTime = details.seekTime
        }
      })

      navigator.mediaSession.setActionHandler('seekbackward', (details) => {
        const skipTime = details.seekOffset || 10
        this.element.currentTime = Math.max(this.element.currentTime - skipTime, 0)
      })

      navigator.mediaSession.setActionHandler('seekforward', (details) => {
        const skipTime = details.seekOffset || 10
        this.element.currentTime = Math.min(
          this.element.currentTime + skipTime,
          this.element.duration
        )
      })

      this.element.addEventListener('timeupdate', () => {
        if ('setPositionState' in navigator.mediaSession) {
          navigator.mediaSession.setPositionState({
            duration: this.element.duration || 0,
            playbackRate: this.element.playbackRate,
            position: this.element.currentTime || 0
          })
        }
      })

      this.element.addEventListener('play', () => {
        navigator.mediaSession.playbackState = 'playing'
      })

      this.element.addEventListener('pause', () => {
        navigator.mediaSession.playbackState = 'paused'
      })

      this.element.addEventListener('ended', () => {
        navigator.mediaSession.playbackState = 'none'
      })
    }
  }

  clearMediaSession() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.metadata = null
      navigator.mediaSession.playbackState = 'none'
    }
  }
}

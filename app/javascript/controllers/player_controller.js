import ApplicationController from "controllers/application_controller"

export default class extends ApplicationController {
  static values = { 
    title: String, 
    artist: String, 
    artwork: String,
    domain: String 
  }

  play() {
    this.element.play().catch(error => {
      console.log("Autoplay prevented:", error)
      // Autoplay was prevented, which is normal on mobile
      // User will need to manually start playback
    })
  }

  attemptPlay() {
    // Only attempt autoplay if user interaction has occurred
    if (this.hasUserInteracted()) {
      this.play()
    }
  }

  setupPlayer() {
    // Setup without attempting autoplay
    this.setupMediaSession()
    this.setupMediaSessionHandlers()
  }

  hasUserInteracted() {
    // Check if there has been user interaction on the page
    return document.hasStoredGesture || 
           document.hasStoredUserActivation ||
           sessionStorage.getItem('userInteracted') === 'true'
  }

  connect() {
    console.log("Connected player controller")
    this.setupMediaSession()
    this.setupMediaSessionHandlers()
    this.trackUserInteraction()
  }

  trackUserInteraction() {
    // Track user interaction for autoplay policies
    const trackInteraction = () => {
      sessionStorage.setItem('userInteracted', 'true')
      document.removeEventListener('click', trackInteraction)
      document.removeEventListener('touchstart', trackInteraction)
    }
    
    document.addEventListener('click', trackInteraction)
    document.addEventListener('touchstart', trackInteraction)
  }

  disconnect() {
    this.clearMediaSession()
  }

  toggle() {
    if (this.element.paused) this.play()
    else this.element.pause()
  }

  // Set up Media Session API for iPhone lock screen integration
  setupMediaSession() {
    if ('mediaSession' in navigator) {
      // Set metadata
      navigator.mediaSession.metadata = new MediaMetadata({
        title: this.titleValue || 'Audio',
        artist: this.artistValue || this.domainValue || 'مكتبة الشيخ',
        artwork: this.getArtworkArray()
      })

      // Set playback state
      navigator.mediaSession.playbackState = 'paused'
    }
  }

  // Get artwork array with domain favicon as fallback
  getArtworkArray() {
    const artworks = []
    
    // Primary artwork (lesson/lecture thumbnail)
    if (this.artworkValue) {
      artworks.push({
        src: this.artworkValue,
        sizes: '512x512',
        type: 'image/png'
      })
    }

    // Domain favicon as fallback (important for iPhone lock screen)
    const faviconLink = document.querySelector('link[rel="apple-touch-icon"]')
    if (faviconLink) {
      artworks.push({
        src: faviconLink.href,
        sizes: '180x180',
        type: 'image/png'
      })
    }

    // Additional favicon sizes
    const faviconLinks = document.querySelectorAll('link[rel="apple-touch-icon"]')
    faviconLinks.forEach(link => {
      if (link.href && !artworks.some(artwork => artwork.src === link.href)) {
        artworks.push({
          src: link.href,
          sizes: link.getAttribute('sizes') || '180x180',
          type: 'image/png'
        })
      }
    })

    return artworks
  }

  // Set up media session action handlers
  setupMediaSessionHandlers() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.setActionHandler('play', () => {
        this.element.play()
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

      // Update position state for better scrubbing on iPhone
      this.element.addEventListener('timeupdate', () => {
        if ('setPositionState' in navigator.mediaSession) {
          navigator.mediaSession.setPositionState({
            duration: this.element.duration || 0,
            playbackRate: this.element.playbackRate,
            position: this.element.currentTime || 0
          })
        }
      })

      // Update playback state
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

  // Clear media session when disconnecting
  clearMediaSession() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.metadata = null
      navigator.mediaSession.playbackState = 'none'
    }
  }
}

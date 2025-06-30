import { Controller } from "@hotwired/stimulus"
import { AudioPlayer } from "../lib/audio_player"

export default class extends Controller {
  static targets = [
    "audio", "playButton", "pauseButton", "progress",
    "time", "duration", "title", "author", "artwork", "player",
    "skeleton", "loopButton", "volumeSlider", "playerContainer",
    "volumeButton", "volumeOnIcon", "volumeOffIcon", "speedSelect"
  ]

  static values = {
    src: String,
    title: String,
    author: String,
    artwork: String,
    autoplay: Boolean
  }

  static globalInstance = null

  connect() {
    this.constructor.globalInstance = this

    this.initializeAudio()
    this.setupAudioPlayer()
    this.bindProgressEvents()

    // Check if there's saved track info and show player if so
    this.checkAndShowSavedTrack()

    if (this.autoplayValue && this.srcValue) {
      this.loadAndPlay(this.srcValue, this.titleValue, this.authorValue, this.artworkValue)
    }

    // Initialize progress fill
    if (this.hasProgressTarget) {
      this.updateRangeFill(
        parseFloat(this.progressTarget.value),
        parseFloat(this.progressTarget.min) || 0,
        parseFloat(this.progressTarget.max) || 100
      )
    }
  }

  disconnect() {
    this.removeEventListeners()
    this.unbindProgressEvents()
    
    if (this.player) {
      this.player.destroy()
    }

    if (this.constructor.globalInstance === this) {
      this.constructor.globalInstance = null
    }
  }

  initializeAudio() {
    if (!this.hasAudioTarget) {
      console.error("[AudioPlayer] Missing audio element in DOM (data-audio-player-target='audio').")
      return
    }
    this.audio = this.audioTarget
    this.audio.preload = 'metadata'
  }

  setupAudioPlayer() {
    this.player = new AudioPlayer(this.audio)
    this.isSeeking = false
    this.isLoading = false
    this.loadingStartTime = null
    this.minimumLoadingTime = 1000 // 1 second minimum
    
    // Set up callbacks
    this.player.on('play', () => this.onPlay())
    this.player.on('pause', () => this.onPause())
    this.player.on('timeUpdate', (currentTime, duration) => this.updateProgress())
    this.player.on('durationChange', (duration) => this.updateDuration())
    this.player.on('trackChange', (track) => this.updateTrackInfo(track.title, track.author, track.artwork))
    this.player.on('volumeChange', (volume) => {
      this.updateVolumeSlider()
      this.updateMuteButton()
    })
    this.player.on('loopChange', (isLooping) => this.updateLoopButton())
    this.player.on('loadStart', () => this.onLoadStart())
    this.player.on('canPlay', () => this.onCanPlay())
    this.player.on('error', (error) => this.onError(error))
    
    // Only show skeleton if no saved track, otherwise checkAndShowSavedTrack will handle display
    const savedTrack = localStorage.getItem('audio_player_current_track')
    if (!savedTrack) {
      this.showSkeleton()
    }
    
    this.updateLoopButton()
    this.updateVolumeSlider()
    this.updateMuteButton()
    
    // Initialize speed control
    if (this.hasSpeedSelectTarget) {
      this.speedSelectTarget.value = "1"
    }
  }

  removeEventListeners() {
    // Event listeners are now managed by the AudioPlayer class
  }

  // Bind range input events for seeking and fill
  bindProgressEvents() {
    if (!this.hasProgressTarget) return

    this.boundOnSeekInput = this.onSeekInput.bind(this)
    this.boundOnSeekChange = this.onSeekChange.bind(this)

    this.progressTarget.addEventListener('input', this.boundOnSeekInput)
    this.progressTarget.addEventListener('change', this.boundOnSeekChange)
  }

  unbindProgressEvents() {
    if (!this.hasProgressTarget) return

    this.progressTarget.removeEventListener('input', this.boundOnSeekInput)
    this.progressTarget.removeEventListener('change', this.boundOnSeekChange)
  }

  // === Audio Controls ===

  play() {
    if (!this.player) return
    this.player.play().catch(error => {
      console.error("[AudioPlayer] Playback failed:", error)
    })
  }

  pause() {
    if (this.player) this.player.pause()
  }

  togglePlay() {
    if (this.player) this.player.togglePlay()
  }

  stop() {
    if (!this.player) return
    this.player.stop()
    this.hidePlayer()
    this.player.destroy();
  }


  toggleLoop() {
    if (this.player) {
      this.player.toggleLoop()
    }
  }

  setVolume(event) {
    const volume = parseFloat(event.target.value) / 100
    if (this.player) {
      this.player.setVolume(volume)
    }
    // Update the visual fill immediately
    const volumePercent = parseFloat(event.target.value)
    event.target.style.background = `linear-gradient(to right, #374151 0%, #374151 ${volumePercent}%, #d1d5db ${volumePercent}%, #d1d5db 100%)`
    
    // Update mute button state
    this.updateMuteButton()
  }

  toggleMute() {
    if (!this.player) return
    
    if (this.audio.volume > 0) {
      // Store current volume and mute
      this.previousVolume = this.audio.volume
      this.player.setVolume(0)
      if (this.hasVolumeSliderTarget) {
        this.volumeSliderTarget.value = 0
        this.volumeSliderTarget.style.background = `linear-gradient(to right, #374151 0%, #374151 0%, #d1d5db 0%, #d1d5db 100%)`
      }
    } else {
      // Restore previous volume or set to 50% if no previous volume
      const volumeToRestore = this.previousVolume || 0.5
      this.player.setVolume(volumeToRestore)
      if (this.hasVolumeSliderTarget) {
        const volumePercent = volumeToRestore * 100
        this.volumeSliderTarget.value = volumePercent
        this.volumeSliderTarget.style.background = `linear-gradient(to right, #374151 0%, #374151 ${volumePercent}%, #d1d5db ${volumePercent}%, #d1d5db 100%)`
      }
    }
    
    this.updateMuteButton()
  }

  setSpeed(event) {
    const speed = parseFloat(event.target.value)
    if (this.audio) {
      this.audio.playbackRate = speed
    }
  }

  playTrack(event) {
    try {
      const button = event.currentTarget
      const audioUrl = button.dataset.audioUrl
      const title = button.dataset.audioTitle || 'Unknown Title'
      const author = button.dataset.audioAuthor || 'Unknown Author'
      const artwork = button.dataset.audioArtwork || ''

      if (!audioUrl) {
        console.warn("[AudioPlayer] No audio URL provided.")
        return
      }

      this.loadAndPlay(audioUrl, title, author, artwork)
    } catch (error) {
      console.error("[AudioPlayer] Error playing track:", error)
    }
  }

  loadAndPlay(src, title = '', author = '', artwork = '') {
    if (!this.player) {
      console.error("[AudioPlayer] Cannot load track: missing player instance.")
      return
    }

    if (!src) {
      console.warn("[AudioPlayer] Empty source. Skipping play.")
      return
    }

    this.isLoading = true
    this.loadingStartTime = Date.now()
    this.showSkeleton()
    this.showPlayer()
    
    this.player.loadTrack(src, title, author, artwork)
  }

  // === Range Progress Bar ===

  updateRangeFill(value, min, max) {
    const fillPercent = ((value - min) / (max - min)) * 100
    this.progressTarget.style.background = `linear-gradient(to right, #374151 0%, #374151 ${fillPercent}%, #d1d5db ${fillPercent}%, #d1d5db 100%)`
  }

  updateDuration() {
    if (!this.player || !this.audio.duration) return
    
    if (this.hasDurationTarget) {
      this.durationTarget.textContent = this.player.formatTime(this.audio.duration)
    }

    // Update max of progress range to 100 (percent)
    if (this.hasProgressTarget) {
      this.progressTarget.min = 0
      this.progressTarget.max = 100
    }
  }

  updateProgress() {
    if (!this.player || !this.audio.duration) return

    if (!this.isSeeking) {
      const percent = this.player.getCurrentProgress()
      this.progressTarget.value = percent
      this.updateRangeFill(percent, this.progressTarget.min || 0, this.progressTarget.max || 100)
    }

    if (this.hasTimeTarget) {
      this.timeTarget.textContent = this.player.formatTime(this.audio.currentTime)
    }
  }

  onSeekInput(event) {
    this.isSeeking = true
    const val = parseFloat(event.target.value)
    this.updateRangeFill(val, parseFloat(event.target.min) || 0, parseFloat(event.target.max) || 100)

    if (this.player && this.audio.duration && this.hasTimeTarget) {
      const previewTime = (val / 100) * this.audio.duration
      this.timeTarget.textContent = this.player.formatTime(previewTime)
    }
  }

  onSeekChange(event) {
    const val = parseFloat(event.target.value)
    if (this.player) {
      this.player.seekPercent(val)
    }
    this.isSeeking = false
  }

  // === UI Updates ===

  updatePlayButton() {
    if (this.isLoading) return

    if (this.hasPlayButtonTarget && this.hasPauseButtonTarget) {
      const isPlaying = this.player?.isPlaying || false
      this.playButtonTarget.style.display = isPlaying ? 'none' : 'flex'
      this.pauseButtonTarget.style.display = isPlaying ? 'flex' : 'none'
    }
  }

  updateLoopButton() {
    if (this.hasLoopButtonTarget && this.player) {
      const isLooping = this.player.isLooping
      this.loopButtonTarget.classList.toggle('text-gray-900', isLooping)
      this.loopButtonTarget.classList.toggle('text-gray-300', !isLooping)
    }
  }

  updateVolumeSlider() {
    if (this.hasVolumeSliderTarget && this.player) {
      const volumePercent = this.player.volume * 100
      this.volumeSliderTarget.value = volumePercent
      this.volumeSliderTarget.style.background = `linear-gradient(to right, #374151 0%, #374151 ${volumePercent}%, #d1d5db ${volumePercent}%, #d1d5db 100%)`
    }
  }

  updateMuteButton() {
    if (this.hasVolumeOnIconTarget && this.hasVolumeOffIconTarget && this.audio) {
      const isMuted = this.audio.volume === 0
      this.volumeOnIconTarget.classList.toggle('hidden', isMuted)
      this.volumeOffIconTarget.classList.toggle('hidden', !isMuted)
    }
  }

  showPlayer() {
    if (this.hasPlayerContainerTarget) {
      this.playerContainerTarget.classList.remove('hidden')
      this.playerContainerTarget.classList.add('flex')
    }
  }

  hidePlayer() {
    if (this.hasPlayerContainerTarget) {
      this.playerContainerTarget.classList.add('hidden')
      this.playerContainerTarget.classList.remove('flex')
    }
  }

  showSkeleton() {
    if (this.hasSkeletonTarget) this.skeletonTarget.classList.remove('hidden')
    if (this.hasPlayerTarget) this.playerTarget.classList.add('hidden')
  }

  hideSkeleton() {
    if (this.hasSkeletonTarget) this.skeletonTarget.classList.add('hidden')
    if (this.hasPlayerTarget) this.playerTarget.classList.remove('hidden')
  }

  // === Audio Events ===

  onLoadStart() {
    console.log("[AudioPlayer] Loading audio…")
    this.isLoading = true
    this.loadingStartTime = Date.now()
    this.showSkeleton()
  }

  onCanPlay() {
    console.log("[AudioPlayer] Can play.")

    const elapsedTime = Date.now() - this.loadingStartTime
    const remainingTime = Math.max(0, this.minimumLoadingTime - elapsedTime)
    
    setTimeout(() => {
      this.isLoading = false

      if (this.player && this.player.currentTrack) {
        this.updateTrackInfo(
          this.player.currentTrack.title,
          this.player.currentTrack.author,
          this.player.currentTrack.artwork
        )
      }

      this.hideSkeleton()
      this.updatePlayButton()
      this.play()
    }, remainingTime)
  }

  onPlay() {
    this.updatePlayButton()
  }

  onPause() {
    this.updatePlayButton()
  }

  onEnded() {
    this.updatePlayButton()
  }

  onError(error) {
    console.error("[AudioPlayer] Audio error:", error)
    this.isLoading = false
    this.hideSkeleton()
    this.updatePlayButton()
  }

  updateTrackInfo(title, author, artwork) {
    if (this.hasTitleTarget) this.titleTarget.textContent = title || 'Unknown Title'
    if (this.hasAuthorTarget) this.authorTarget.textContent = author || 'Unknown Author'
    if (this.hasArtworkTarget) this.artworkTarget.src = artwork || ''
  }

  // === Static API ===

  static getInstance() {
    return this.globalInstance
  }

  static playGlobal(src, title, author, artwork) {
    const instance = this.getInstance()
    if (instance) {
      instance.loadAndPlay(src, title, author, artwork)
    } else {
      console.warn("[AudioPlayer] No global instance available.")
    }
  }

  checkAndShowSavedTrack() {
    // Check if there's saved track information
    const savedTrack = localStorage.getItem('audio_player_current_track')
    if (savedTrack) {
      try {
        const trackData = JSON.parse(savedTrack)
        // Only show if it's been less than 1 hour since last play
        const hoursSinceLastPlay = (Date.now() - trackData.timestamp) / (1000 * 60 * 60)
        if (hoursSinceLastPlay < 1) {
          // Show the player immediately with saved track info
          this.showPlayer()
          this.hideSkeleton()
          
          // Update track info display
          this.updateTrackInfo(trackData.title, trackData.author, trackData.artwork)
          
          // The AudioPlayer class will handle restoring the actual audio state
        }
      } catch (e) {
        console.warn('[AudioPlayer] Failed to check saved track:', e)
      }
    }
  }
}

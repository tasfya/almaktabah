/**
 * AudioPlayer - Enhanced audio player with local storage and persistent playback
 */
export class AudioPlayer {
  constructor(audioElement) {
    this.audio = audioElement
    this.isPlaying = false
    this.currentTrack = null
    this.volume = 1.0
    this.isLooping = false
    this.playbackRate = 1.0
    
    // Storage keys
    this.STORAGE_KEYS = {
      CURRENT_TRACK: 'audio_player_current_track',
      PROGRESS: 'audio_player_progress',
      VOLUME: 'audio_player_volume',
      LOOP: 'audio_player_loop',
      PLAYING_STATE: 'audio_player_playing_state',
      SPEED: 'audio_player_speed'
    }
    
    // Event callbacks
    this.callbacks = {
      onPlay: null,
      onPause: null,
      onTimeUpdate: null,
      onDurationChange: null,
      onTrackChange: null,
      onVolumeChange: null,
      onLoopChange: null,
      onLoadStart: null,
      onCanPlay: null,
      onError: null
    }
    
    this.init()
  }
  
  init() {
    this.loadSettings()
    this.bindAudioEvents()
    this.setupProgressSaving()
    this.restoreCurrentTrack()
  }
  
  bindAudioEvents() {
    this.audio.addEventListener('play', () => {
      this.isPlaying = true
      this.callbacks.onPlay?.()
    })
    
    this.audio.addEventListener('pause', () => {
      this.isPlaying = false
      this.callbacks.onPause?.()
    })
    
    this.audio.addEventListener('timeupdate', () => {
      this.saveProgress()
      this.callbacks.onTimeUpdate?.(this.audio.currentTime, this.audio.duration)
    })
    
    this.audio.addEventListener('loadedmetadata', () => {
      this.restoreProgress()
      this.callbacks.onDurationChange?.(this.audio.duration)
    })
    
    this.audio.addEventListener('ended', () => {
      if (this.isLooping) {
        this.seek(0)
        this.play()
      } else {
        this.isPlaying = false
        this.callbacks.onPause?.()
      }
    })
    
    this.audio.addEventListener('loadstart', () => {
      this.callbacks.onLoadStart?.()
    })
    
    this.audio.addEventListener('canplay', () => {
      this.callbacks.onCanPlay?.()
    })
    
    this.audio.addEventListener('error', (error) => {
      this.callbacks.onError?.(error)
    })
    
    this.audio.addEventListener('volumechange', () => {
      this.volume = this.audio.volume
      this.saveVolume()
      this.callbacks.onVolumeChange?.(this.volume)
    })
  }
  
  setupProgressSaving() {
    // Save progress every 5 seconds
    this.progressSaveInterval = setInterval(() => {
      if (this.isPlaying && this.currentTrack) {
        this.saveProgress()
      }
    }, 5000)
  }
  
  loadSettings() {
    // Load volume
    const savedVolume = localStorage.getItem(this.STORAGE_KEYS.VOLUME)
    if (savedVolume !== null) {
      this.volume = parseFloat(savedVolume)
      this.audio.volume = this.volume
    }
    
    // Load loop state
    const savedLoop = localStorage.getItem(this.STORAGE_KEYS.LOOP)
    if (savedLoop !== null) {
      this.isLooping = savedLoop === 'true'
    }
    
    // Load speed/playback rate
    const savedSpeed = localStorage.getItem(this.STORAGE_KEYS.SPEED)
    if (savedSpeed !== null) {
      this.playbackRate = parseFloat(savedSpeed)
      this.audio.playbackRate = this.playbackRate
    }
  }

  restoreCurrentTrack() {
    const savedTrack = localStorage.getItem(this.STORAGE_KEYS.CURRENT_TRACK)
    if (savedTrack) {
      try {
        const trackData = JSON.parse(savedTrack)
        const savedProgress = localStorage.getItem(this.STORAGE_KEYS.PROGRESS)
        const wasPlaying = localStorage.getItem(this.STORAGE_KEYS.PLAYING_STATE) === 'true'
        
        // Only restore if it's been less than 1 hour
        const hoursSinceLastPlay = (Date.now() - trackData.timestamp) / (1000 * 60 * 60)
        if (hoursSinceLastPlay < 1) {
          this.loadTrack(trackData.src, trackData.title, trackData.author, trackData.artwork)
          
          // Restore progress after metadata loads
          if (savedProgress) {
            const progressData = JSON.parse(savedProgress)
            this.audio.addEventListener('loadedmetadata', () => {
              this.audio.currentTime = progressData.currentTime
              if (wasPlaying) {
                this.play()
              }
            }, { once: true })
          }
        }
      } catch (e) {
        console.warn('[AudioPlayer] Failed to restore track:', e)
      }
    }
  }
  
  saveProgress() {
    if (!this.currentTrack || !this.audio.duration || this.audio.duration === 0) return
    
    const progress = {
      trackId: this.getTrackId(),
      currentTime: this.audio.currentTime,
      duration: this.audio.duration,
      timestamp: Date.now()
    }
    
    localStorage.setItem(this.STORAGE_KEYS.PROGRESS, JSON.stringify(progress))
    
    // Save playing state
    localStorage.setItem(this.STORAGE_KEYS.PLAYING_STATE, this.isPlaying.toString())
  }

  saveCurrentTrack() {
    if (!this.currentTrack) return
    
    const trackData = {
      src: this.currentTrack.src,
      title: this.currentTrack.title,
      author: this.currentTrack.author,
      artwork: this.currentTrack.artwork,
      timestamp: Date.now()
    }
    
    localStorage.setItem(this.STORAGE_KEYS.CURRENT_TRACK, JSON.stringify(trackData))
  }
  
  restoreProgress() {
    if (!this.currentTrack) return
    
    const savedProgress = localStorage.getItem(this.STORAGE_KEYS.PROGRESS)
    if (!savedProgress) return
    
    try {
      const progress = JSON.parse(savedProgress)
      if (progress.trackId === this.getTrackId() && progress.currentTime > 0) {
        // Only restore if it's been less than 24 hours
        const hoursSinceLastPlay = (Date.now() - progress.timestamp) / (1000 * 60 * 60)
        if (hoursSinceLastPlay < 24) {
          this.audio.currentTime = progress.currentTime
        }
      }
    } catch (e) {
      console.warn('[AudioPlayer] Failed to restore progress:', e)
    }
  }
  
  saveVolume() {
    localStorage.setItem(this.STORAGE_KEYS.VOLUME, this.volume.toString())
  }
  
  saveLoop() {
    localStorage.setItem(this.STORAGE_KEYS.LOOP, this.isLooping.toString())
  }
  
  saveSpeed() {
    localStorage.setItem(this.STORAGE_KEYS.SPEED, this.playbackRate.toString())
  }
  
  getTrackId() {
    if (!this.currentTrack) return null
    return `${this.currentTrack.src}_${this.currentTrack.title}`
  }
  
  // Public API
  loadTrack(src, title = '', author = '', artwork = '') {
    this.currentTrack = { src, title, author, artwork }
    this.audio.src = src
    this.saveCurrentTrack()
    this.callbacks.onTrackChange?.(this.currentTrack)
  }
   play() {
    if (!this.audio.src) return Promise.reject(new Error('No track loaded'))
    const playPromise = this.audio.play()
    if (playPromise) {
      playPromise.then(() => {
        localStorage.setItem(this.STORAGE_KEYS.PLAYING_STATE, 'true')
      }).catch(error => {
        localStorage.setItem(this.STORAGE_KEYS.PLAYING_STATE, 'false')
        throw error
      })
    }
    return playPromise
  }

  pause() {
    this.audio.pause()
    localStorage.setItem(this.STORAGE_KEYS.PLAYING_STATE, 'false')
  }
  
  stop() {
    console.log('Stopping audio playback')
    this.audio.pause()
    this.audio.currentTime = 0
    this.isPlaying = false
    localStorage.setItem(this.STORAGE_KEYS.PLAYING_STATE, 'false')
    localStorage.removeItem(this.STORAGE_KEYS.CURRENT_TRACK)
    localStorage.removeItem(this.STORAGE_KEYS.PROGRESS)
  }
  
  togglePlay() {
    return this.isPlaying ? this.pause() : this.play()
  }
  
  seek(time) {
    if (this.audio.duration && time >= 0 && time <= this.audio.duration) {
      this.audio.currentTime = time
    }
  }
  
  seekPercent(percent) {
    if (this.audio.duration) {
      const time = (percent / 100) * this.audio.duration
      this.seek(time)
    }
  }
  
  setVolume(volume) {
    this.volume = Math.max(0, Math.min(1, volume))
    this.audio.volume = this.volume
  }
  
  toggleLoop() {
    this.isLooping = !this.isLooping
    this.saveLoop()
    this.callbacks.onLoopChange?.(this.isLooping)
    return this.isLooping
  }
  
    
  formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00'
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.floor(seconds % 60)
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  }
  
  getCurrentProgress() {
    if (!this.audio.duration) return 0
    return (this.audio.currentTime / this.audio.duration) * 100
  }
  
  // Event listener management
  on(event, callback) {
    if (this.callbacks.hasOwnProperty(`on${event.charAt(0).toUpperCase() + event.slice(1)}`)) {
      this.callbacks[`on${event.charAt(0).toUpperCase() + event.slice(1)}`] = callback
    }
  }
  
  destroy() {
    if (this.progressSaveInterval) {
      clearInterval(this.progressSaveInterval)
    }
    this.saveProgress()
    this.audio.src = null
  }
}

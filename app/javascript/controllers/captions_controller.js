import ApplicationController from "controllers/application_controller"

// connects to data-controller="captions"
export default class extends ApplicationController {
  static values = {
    playerId: String,
    segments: Array
  }

  static targets = ["display"]

  connect() {
    this._retryCount = 0
    this._activeIndex = null
    this._attachAudio()
  }

  disconnect() {
    if (this.audio) {
      this.audio.removeEventListener('timeupdate', this._boundTimeupdate)
      this.audio.removeEventListener('play', this._onPlay)
      this.audio.removeEventListener('pause', this._onPause)
      if (this.track && this._cueChangeHandler) this.track.removeEventListener('cuechange', this._cueChangeHandler)
    }
  }

  _attachAudio() {
    const playerId = this.playerIdValue || this.element.dataset.playerId || null
    if (!playerId) return

    this.audio = document.getElementById(playerId)

    if (this.audio) {
      this._boundTimeupdate = this._onTimeUpdate.bind(this)
      this._onPlay = this._showDisplay.bind(this)
      this._onPause = this._hideDisplay.bind(this)

      this.audio.addEventListener('timeupdate', this._boundTimeupdate)
      this.audio.addEventListener('play', this._onPlay)
      this.audio.addEventListener('pause', this._onPause)
      this.audio.addEventListener('ended', this._onPause)

      // Build a text track and cues where possible, and also fallback to manual scanning for tests
      this._buildTrack()

      // Initial sync
      this._onTimeUpdate()
    } else {
      this._retryCount += 1
      if (this._retryCount < 10) setTimeout(() => this._attachAudio(), 200)
    }
  }

  _buildTrack() {
    // Support either an Array or a JSON string in the attribute (defensive).
    let segments = this.segmentsValue
    if (typeof segments === 'string') {
      try { segments = JSON.parse(segments) } catch (e) { segments = [] }
    }
    if (!segments || !segments.length) return

    try {
      this.track = this.audio.addTextTrack('captions', 'captions', 'ar')
      this.track.mode = 'hidden'

      const CueClass = window.VTTCue || window.TextTrackCue
      segments.forEach(s => {
        const start = parseFloat(s.start || 0)
        const end = parseFloat(s.end || 0)
        const text = String(s.text || '')

        if (typeof CueClass === 'function') {
          const cue = new CueClass(start, end, text)
          this.track.addCue(cue)
        }
      })

      // cuechange handler
      this._cueChangeHandler = () => {
        const active = (this.track && this.track.activeCues && this.track.activeCues[0]) || null
        if (active) this._setDisplay(active.text)
        else this._setDisplay('')
      }
      this.track.addEventListener('cuechange', this._cueChangeHandler)

      // Safari oddness: toggle to ensure events work
      try { this.track.mode = 'showing'; this.track.mode = 'hidden' } catch (e) { /* ignore */ }
    } catch (err) {
      // ignore track creation failures
      console.warn('captions controller: failed to create text track', err)
    }
  }

  _onTimeUpdate() {
    const t = this.audio ? this.audio.currentTime : 0

    // Prefer native text track activeCues when available
    if (this.track && this.track.activeCues && this.track.activeCues.length) {
      const active = this.track.activeCues[0]
      this._setDisplay(active.text)
      return
    }

    // Fallback: manual scan of provided segments (supports array or JSON string)
    let segments = this.segmentsValue
    if (typeof segments === 'string') {
      try { segments = JSON.parse(segments) } catch (e) { segments = [] }
    }

    let activeSeg = null
    for (let i = 0; i < (segments || []).length; i++) {
      const s = parseFloat(segments[i].start || 0)
      const e = parseFloat(segments[i].end || 0)
      if (t >= (s - 0.2) && t < (e - 0.1)) {
        activeSeg = segments[i]
        break
      }
    }

    this._setDisplay(activeSeg ? String(activeSeg.text || '') : '')
  }

  _setDisplay(text) {
    if (!this.hasDisplayTarget) return
    if (text && text.length) {
      this.displayTarget.textContent = text
      this.displayTarget.classList.remove('hidden')
      this.displayTarget.removeAttribute('aria-hidden')
    } else {
      this.displayTarget.textContent = ''
      this.displayTarget.classList.add('hidden')
      this.displayTarget.setAttribute('aria-hidden', 'true')
    }
  }

  _showDisplay() {
    // Always reveal the captions container on play (content may be empty until first cue/timeupdate)
    if (this.hasDisplayTarget) {
      this.displayTarget.classList.remove('hidden')
      this.displayTarget.removeAttribute('aria-hidden')
    }
  }

  _hideDisplay() {
    if (this.hasDisplayTarget) {
      this.displayTarget.classList.add('hidden')
      this.displayTarget.setAttribute('aria-hidden', 'true')
    }
  }
}

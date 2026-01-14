import ApplicationController from "controllers/application_controller"

// connects to data-controller="transcript"
export default class extends ApplicationController {
  static values = {
    playerId: String
  }

  static targets = ["segment"]

  connect() {
    this._boundTimeupdate = this._onTimeUpdate.bind(this)
    this._retryCount = 0
    this._attachAudio()
  }

  disconnect() {
    if (this.audio && this._boundTimeupdate) {
      this.audio.removeEventListener('timeupdate', this._boundTimeupdate)
      this.audio.removeEventListener('seeked', this._boundTimeupdate)
    }
  }

  _attachAudio() {
    const playerId = this.playerIdValue || this.element.dataset.playerId || null
    if (!playerId) return

    this.audio = document.getElementById(playerId)
    if (this.audio) {
      this.audio.addEventListener('timeupdate', this._boundTimeupdate)
      this.audio.addEventListener('seeked', this._boundTimeupdate)
      // initial update
      this._onTimeUpdate()
    } else {
      // retry a few times in case audio element is not yet present
      this._retryCount += 1
      if (this._retryCount < 10) {
        setTimeout(() => this._attachAudio(), 200)
      }
    }
  }

  _onTimeUpdate() {
    const t = this.audio ? this.audio.currentTime : 0
    let active = null

    this.segmentTargets.forEach(seg => {
      const s = parseFloat(seg.dataset.startValue || seg.dataset.start || 0)
      const e = parseFloat(seg.dataset.endValue || seg.dataset.end || (s + 5))

      // clear previous active styles
      seg.classList.remove('bg-yellow-100', 'ring', 'ring-yellow-200')
      seg.removeAttribute('aria-current')

      // consider active if currentTime is within [start - 0.2, end - 0.1)
      if (t >= (s - 0.2) && t < (e - 0.1)) {
        active = seg
      }
    })

    if (active) {
      active.classList.add('bg-yellow-100', 'ring', 'ring-yellow-200')
      active.setAttribute('aria-current', 'true')

      const playerId = this.playerIdValue || this.element.dataset.playerId || null

      // Attempt to scroll within the player content container so the audio player remains visible
      let container = null
      if (playerId) {
        container = document.getElementById(`${playerId}_player_content`)
      }
      if (!container) {
        // fallback to nearest scrollable ancestor
        container = this.element.closest('.overflow-y-auto') || document.scrollingElement || document.documentElement
      }

      try {
        if (container && container.scrollTop !== undefined) {
          const containerRect = container.getBoundingClientRect()
          const activeRect = active.getBoundingClientRect()
          const offsetTop = activeRect.top - containerRect.top
          const scrollTarget = container.scrollTop + offsetTop - (container.clientHeight / 2) + (active.clientHeight / 2)
          container.scrollTo({ top: Math.max(0, scrollTarget), behavior: 'smooth' })
        } else {
          // fallback to default
          active.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
        }
      } catch (e) {
        // ignore failures and fallback
        active.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      }

      // Ensure the audio player element is visible in the viewport (window)
      if (playerId) {
        const playerEl = document.getElementById(playerId)
        if (playerEl) {
          const pr = playerEl.getBoundingClientRect()
          const margin = 10
          if (pr.bottom > (window.innerHeight - margin)) {
            window.scrollBy({ top: pr.bottom - window.innerHeight + margin, behavior: 'smooth' })
          } else if (pr.top < margin) {
            window.scrollBy({ top: pr.top - margin, behavior: 'smooth' })
          }
        }
      }
    }
  }

  seek(event) {
    event.preventDefault()

    const startAttr = event.currentTarget.dataset.startValue || event.currentTarget.dataset.start
    const start = parseFloat(startAttr || 0)

    const playerId = this.playerIdValue || this.element.dataset.playerId || null
    if (!playerId) {
      console.warn('transcript controller: no player id provided')
      return
    }

    const audio = document.getElementById(playerId)
    if (!audio) {
      console.warn('transcript controller: audio element not found for id', playerId)
      return
    }

    // Seek and play
    audio.currentTime = start
    // Try to play, ignore promise rejection if autoplay is blocked
    const p = audio.play()
    if (p && typeof p.then === 'function') {
      p.catch(() => {})
    }

    // Minor UI feedback: add a temporary highlight to clicked segment
    const el = event.currentTarget
    el.classList.add('bg-yellow-50')
    setTimeout(() => el.classList.remove('bg-yellow-50'), 700)

    // ensure the active highlight updates after seeking
    setTimeout(() => this._onTimeUpdate(), 150)
  }
}

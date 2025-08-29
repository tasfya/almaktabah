import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values = { 
    speed: { type: Number, default: 4000 },
    pauseOnHover: { type: Boolean, default: true }
  }

  connect() {
    if (this.itemTargets.length === 0) return
    
    this.currentIndex = 0
    this.isAnimating = false
    this.intervalId = null
    
    this.showCurrentItem()
    this.startAnimation()
  }

  disconnect() {
    this.stopAnimation()
  }

  showCurrentItem() {
    this.itemTargets.forEach((item, index) => {
      if (index === this.currentIndex) {
        item.classList.remove('hidden')
        item.classList.add('flex')
      } else {
        item.classList.add('hidden')
        item.classList.remove('flex')
      }
    })
  }

  nextItem() {
    if (this.itemTargets.length === 0) return

    this.nextIndex = (this.currentIndex + 1) % this.itemTargets.length
    const nextElement = this.itemTargets[this.nextIndex]
    const currentElement = this.itemTargets[this.currentIndex]

    currentElement.classList.remove('flex')
    currentElement.classList.add('hidden')

    nextElement.classList.remove('hidden')
    nextElement.classList.add('flex')

    this.currentIndex = this.nextIndex
  }

  startAnimation() {
    if (this.isAnimating || this.itemTargets.length <= 1) return
    
    this.isAnimating = true
    this.intervalId = setInterval(() => {
      this.nextItem()
    }, this.speedValue)
  }

  stopAnimation() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    this.isAnimating = false
  }

  pauseAnimation() {
    if (this.pauseOnHoverValue) {
      this.stopAnimation()
    }
  }

  resumeAnimation() {
    if (this.pauseOnHoverValue) {
      this.startAnimation()
    }
  }
}

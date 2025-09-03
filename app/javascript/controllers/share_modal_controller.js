import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    url: String,
    title: String,
    text: String
  }
  static targets = [
    "modal", 
    "urlInput", 
    "copyButton", 
    "copyIcon", 
    "feedback", 
    "successMessage", 
    "errorMessage"
  ]

  connect() {
    if (!this.urlValue) {
      this.urlValue = window.location.href
    }
    if (!this.titleValue) {
      this.titleValue = document.title
    }
  }

  open() {
    this.modalTarget.showModal()
  }

  close() {
    this.modalTarget.close()
  }

  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  // Copy link to clipboard
  copyLink(event) {
    event.preventDefault()
    
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(this.urlValue)
        .then(() => {
          this.showInlineSuccess()
        })
        .catch((err) => {
          console.error("Error copying to clipboard: ", err)
          this.fallbackCopy()
        })
    } else {
      this.fallbackCopy()
    }
  }

  // Fallback copy method for older browsers
  fallbackCopy() {
    const textArea = document.createElement("textarea")
    textArea.value = this.urlValue
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showInlineSuccess()
    } catch (err) {
      console.error("Error copying to clipboard: ", err)
      this.showInlineError()
    } finally {
      document.body.removeChild(textArea)
    }
  }

  shareTwitter(event) {
    event.preventDefault()
    const text = this.textValue || this.titleValue
    const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(this.urlValue)}`
    window.open(url, '_blank', 'noopener,noreferrer')
  }

  shareFacebook(event) {
    event.preventDefault()
    const url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.urlValue)}`
    window.open(url, '_blank', 'noopener,noreferrer')
  }

  shareWhatsApp(event) {
    event.preventDefault()
    const text = this.textValue || this.titleValue
    const url = `https://wa.me/?text=${encodeURIComponent(`${text} ${this.urlValue}`)}`
    window.open(url, '_blank', 'noopener,noreferrer')
  }

  shareTelegram(event) {
    event.preventDefault()
    const text = this.textValue || this.titleValue
    const url = `https://t.me/share/url?url=${encodeURIComponent(this.urlValue)}&text=${encodeURIComponent(text)}`
    window.open(url, '_blank', 'noopener,noreferrer')
  }

  showInlineSuccess() {
    this.hideAllMessages()
    
    this.feedbackTarget.classList.remove("hidden")
    this.successMessageTarget.classList.remove("hidden")
    
    setTimeout(() => {
      this.resetFeedback()
    }, 3000)
    
    this.dispatch("copied", { 
      detail: { 
        url: this.urlValue,
        success: true 
      } 
    })
  }

  showInlineError() {
    this.hideAllMessages()
    
    this.feedbackTarget.classList.remove("hidden")
    this.errorMessageTarget.classList.remove("hidden")

    setTimeout(() => {
      this.resetFeedback()
    }, 5000)
    
    this.dispatch("error", { 
      detail: { 
        url: this.urlValue,
        success: false 
      } 
    })
  }

  hideAllMessages() {
    this.successMessageTarget.classList.add("hidden")
    this.errorMessageTarget.classList.add("hidden")
  }

  resetFeedback() {
    this.feedbackTarget.classList.add("hidden")
    this.hideAllMessages()
  }
}

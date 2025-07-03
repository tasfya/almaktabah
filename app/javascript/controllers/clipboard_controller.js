import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    text: String,
    successMessage: String,
    errorMessage: String
  }

  connect() {
    if (!this.successMessageValue) {
      this.successMessageValue = "تم نسخ الرابط بنجاح!"
    }
    if (!this.errorMessageValue) {
      this.errorMessageValue = "خطأ في نسخ الرابط"
    }
  }

  copy(event) {
    event.preventDefault()
    
    const textToCopy = this.textValue || this.element.dataset.clipboardText
    
    if (!textToCopy) {
      console.error("No text provided to copy")
      return
    }
    
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(textToCopy)
        .then(() => {
          this.showSuccess()
        })
        .catch((err) => {
          console.error(this.errorMessageValue + ": ", err)
          this.fallbackCopy(textToCopy)
        })
    } else {
      // Fallback
      this.fallbackCopy(textToCopy)
    }
  }

  fallbackCopy(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showSuccess()
    } catch (err) {
      console.error(this.errorMessageValue + ": ", err)
      this.showError()
    } finally {
      document.body.removeChild(textArea)
    }
  }

  showSuccess() {
    alert(this.successMessageValue)
    this.dispatch("copied", { 
      detail: { 
        text: this.textValue,
        success: true 
      } 
    })
  }

  showError() {
    alert(this.errorMessageValue)    
    this.dispatch("error", { 
      detail: { 
        text: this.textValue,
        success: false 
      } 
    })
  }
}

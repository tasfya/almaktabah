import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoriesDropdown", "categoryButton"]

  connect() {
    this.isOpen = false
    // Close dropdown when clicking outside
    this.handleClickOutside = this.handleClickOutside.bind(this)
    this.handleScroll = this.handleScroll.bind(this)
    document.addEventListener("click", this.handleClickOutside)
    window.addEventListener("scroll", this.handleScroll)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    window.removeEventListener("scroll", this.handleScroll)
  }

  toggleCategories(event) {
    event.stopPropagation()
    this.isOpen = !this.isOpen
    
    if (this.isOpen) {
      this.categoriesDropdownTarget.classList.remove("hidden")
      this.categoriesDropdownTarget.classList.add("animate-fadeIn")
    } else {
      this.categoriesDropdownTarget.classList.add("hidden")
    }
  }

  handleClickOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.isOpen = false
      this.categoriesDropdownTarget.classList.add("hidden")
    }
  }

  handleScroll() {
    if (this.isOpen) {
      this.closeDropdown()
    }
  }

  closeDropdown() {
    this.isOpen = false
    this.categoriesDropdownTarget.classList.add("hidden")
  }

  preventClose(event) {
    event.stopPropagation()
  }

  onFocus(event) {
    event.target.parentElement.classList.add("ring-2", "ring-primary/30")
  }

  onBlur(event) {
    event.target.parentElement.classList.remove("ring-2", "ring-primary/30")
  }
}

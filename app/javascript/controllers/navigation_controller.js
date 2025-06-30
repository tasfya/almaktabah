import { Controller } from "@hotwired/stimulus"

// Navigation controller for mobile menu and user menu
export default class extends Controller {
  static targets = ["menu", "overlay", "userMenu"]
  
  connect() {
    this.menuOpen = false
    this.userMenuOpen = false
  }
  
  toggleMobileMenu() {
    this.menuOpen = !this.menuOpen
    
    if (this.hasMenuTarget) {
      if (this.menuOpen) {
        this.menuTarget.classList.remove('hidden')
        this.menuTarget.classList.add('block')
      } else {
        this.menuTarget.classList.add('hidden')
        this.menuTarget.classList.remove('block')
      }
    }
    
    if (this.hasOverlayTarget) {
      if (this.menuOpen) {
        this.overlayTarget.classList.remove('hidden')
      } else {
        this.overlayTarget.classList.add('hidden')
      }
    }
  }
  
  toggleUserMenu() {
    this.userMenuOpen = !this.userMenuOpen
    
    if (this.hasUserMenuTarget) {
      if (this.userMenuOpen) {
        this.userMenuTarget.classList.remove('hidden')
      } else {
        this.userMenuTarget.classList.add('hidden')
      }
    }
  }
  
  closeMobileMenu() {
    this.menuOpen = false
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
      this.menuTarget.classList.remove('block')
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden')
    }
  }
  
  closeUserMenu() {
    this.userMenuOpen = false
    if (this.hasUserMenuTarget) {
      this.userMenuTarget.classList.add('hidden')
    }
  }
  
  // Close menus when clicking outside
  clickOutside(event) {
    if (this.menuOpen && this.hasOverlayTarget && event.target === this.overlayTarget) {
      this.closeMobileMenu()
    }
  }
}

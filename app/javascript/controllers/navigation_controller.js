import { Controller } from "@hotwired/stimulus";

// Navigation controller for mobile menu and user menu
export default class extends Controller {
  static targets = ["menu", "overlay", "menuButton"];

  connect() {
    this.menuOpen = false;
    this._onKeydown = this._onKeydown.bind(this);
    document.addEventListener("keydown", this._onKeydown);
  }

  toggleMobileMenu() {
    if (this.menuOpen) {
      this.closeMobileMenu();
    } else {
      this.openMobileMenu();
    }
  }

  openMobileMenu() {
    this.menuOpen = true;
    this.menuTarget.classList.remove("hidden");
    this.menuTarget.classList.add("block");
    this.menuButtonTarget.setAttribute("aria-expanded", "true");
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden");
    }
    document.body.classList.add("overflow-hidden");
  }

  closeMobileMenu() {
    this.menuOpen = false;
    this.menuTarget.classList.add("hidden");
    this.menuTarget.classList.remove("block");
    this.menuButtonTarget.setAttribute("aria-expanded", "false");
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden");
    }
    document.body.classList.remove("overflow-hidden");
  }

  _onKeydown(event) {
    if (event.key === "Escape" && this.menuOpen) {
      if (!this.menuOpen) return;
      if (e.key === "Escape" || e.key === "Esc") {
        this.closeMobileMenu();
        this.menuButtonTarget.focus();
      }
    }
  }

  // Close menus when clicking outside
  clickOutside(event) {
    if (
      this.menuOpen &&
      this.hasOverlayTarget &&
      event.target === this.overlayTarget
    ) {
      this.closeMobileMenu();
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown);
    if (this.menuOpen) {
      document.body.classList.remove("overflow-hidden");
    }
  }
}

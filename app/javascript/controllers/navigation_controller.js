import { Controller } from "@hotwired/stimulus";

// Navigation controller for mobile menu and user menu
export default class extends Controller {
  static targets = ["menu", "overlay", "menuButton"];

  connect() {
    this.menuOpen = false;
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
    this.menuTarget.setAttribute("aria-hidden", "false");
    this.menuButtonTarget.setAttribute("aria-expanded", "true");
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden");
    }
  }

  closeMobileMenu() {
    this.menuOpen = false;
    this.menuTarget.classList.add("hidden");
    this.menuTarget.classList.remove("block");
    this.menuTarget.setAttribute("aria-hidden", "true");
    this.menuButtonTarget.setAttribute("aria-expanded", "false");
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden");
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
}

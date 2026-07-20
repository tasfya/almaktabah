import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["logo", "nav"];
  static values = { threshold: { type: Number, default: 200 } };

  connect() {
    this.compact = false;
    this.lastScrollY = 0;
    this.ticking = false;
    this._onScroll = this._onScroll.bind(this);
    
    // Add transition to header
    this.element.style.transition = "transform 0.3s ease-in-out";
    
    window.addEventListener("scroll", this._onScroll, { passive: true });
    this._checkScroll();
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll);
  }

  _onScroll() {
    this.lastScrollY = window.scrollY;
    
    if (!this.ticking) {
      window.requestAnimationFrame(() => {
        this._checkScroll();
        this.ticking = false;
      });
      this.ticking = true;
    }
  }

  _checkScroll() {
    const scrollY = this.lastScrollY;
    const shouldHide = scrollY > this.thresholdValue;

    if (shouldHide !== this.compact) {
      this.compact = shouldHide;
      this._updateCompactState();
    }
  }

  _updateCompactState() {
    if (this.compact) {
      this.element.classList.add("header--compact");
      this.element.style.transform = "translateY(-100%)";
    } else {
      this.element.classList.remove("header--compact");
      this.element.style.transform = "translateY(0)";
    }
  }
}

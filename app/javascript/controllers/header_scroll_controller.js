import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["header", "spacer", "logo", "nav"];
  static values = { threshold: { type: Number, default: 50 } };

  connect() {
    this.compact = false;
    this._onScroll = this._onScroll.bind(this);
    this._resizeObserver = new ResizeObserver(() => this._reserveSpace());
    this._resizeObserver.observe(this.headerTarget);
    this._reserveSpace();
    window.addEventListener("scroll", this._onScroll, { passive: true });
    this._onScroll();
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll);
    this._resizeObserver.disconnect();
  }

  // The header is fixed and the spacer keeps its expanded height in the flow.
  // If compacting moved the content instead, scroll anchoring would pull scrollY
  // back under the threshold, expand the header again, and trap small scroll
  // steps at the top of the page.
  _reserveSpace() {
    if (this.compact) return;
    this.spacerTarget.style.height = `${this.headerTarget.offsetHeight}px`;
  }

  _onScroll() {
    const scrollY = window.scrollY;
    const shouldCompact = scrollY > this.thresholdValue;

    if (shouldCompact !== this.compact) {
      this.compact = shouldCompact;
      this._updateCompactState();
    }
  }

  _updateCompactState() {
    if (this.compact) {
      this.element.classList.add("header--compact");
      if (this.hasLogoTarget) this.logoTarget.classList.add("hidden");
      if (this.hasNavTarget) this.navTarget.classList.add("header--nav-hidden");
    } else {
      this.element.classList.remove("header--compact");
      if (this.hasLogoTarget) this.logoTarget.classList.remove("hidden");
      if (this.hasNavTarget) this.navTarget.classList.remove("header--nav-hidden");
    }
  }
}

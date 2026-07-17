import { Controller } from "@hotwired/stimulus";

// Drives the search filter sidebar. Filter changes submit the GET filter form,
// which Turbo turns into a navigation of the ancestor `search_content` frame
// (data-turbo-action="advance"). That gives every filter state a real history
// entry and a server-rendered snapshot matching its URL, so browser Back/Forward
// stay consistent (issue #385). No manual fetch, replaceState or popstate here —
// Turbo owns history and rendering.
//
// Desktop (sidebar always visible): submit on checkbox change (debounced).
// Mobile (drawer): submit on the Apply button only, so ticking several boxes is
// one history entry and the drawer isn't torn down on every tick.
export default class extends Controller {
  static targets = [
    "sidebar",
    "toggle",
    "overlay",
    "checkboxToggle",
  ];

  static values = {
    open: { type: Boolean, default: false },
  };

  connect() {
    this.debounceTimeout = null;
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.boundHandleClickOutside = this.handleClickOutside.bind(this);
    this.boundHandleResize = this.handleResize.bind(this);
    this.boundHandleCheckboxToggle = this.handleCheckboxToggle.bind(this);

    document.addEventListener("keydown", this.boundHandleKeydown);
    document.addEventListener("click", this.boundHandleClickOutside);
    window.addEventListener("resize", this.boundHandleResize);

    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.addEventListener(
        "change",
        this.boundHandleCheckboxToggle
      );
    }

    this.setInitialSidebarState();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown);
    document.removeEventListener("click", this.boundHandleClickOutside);
    window.removeEventListener("resize", this.boundHandleResize);
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.removeEventListener(
        "change",
        this.boundHandleCheckboxToggle
      );
    }
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
    // The frame navigation that closes the mobile drawer replaces these nodes
    // rather than calling close(), so clear the scroll lock here to be safe.
    document.body.classList.remove("overflow-hidden");
  }

  handleCheckboxToggle() {
    this.openValue = this.checkboxToggleTarget.checked;
    this.updateSidebarState();
  }

  toggle() {
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.checked = !this.checkboxToggleTarget.checked;
      this.openValue = this.checkboxToggleTarget.checked;
    } else {
      this.openValue ? this.close() : this.open();
    }
  }

  open() {
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.checked = true;
    }
    this.openValue = true;
    this.updateSidebarState();
    this.trapFocus();
  }

  close() {
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.checked = false;
    }
    this.openValue = false;
    this.updateSidebarState();
    this.removeFocusTrap();
  }

  // Desktop: submit (debounced) as soon as a filter checkbox changes. On mobile
  // we wait for the Apply button so several ticks become a single history entry.
  onCheckboxChange(event) {
    this.changedForm = event.target.form;
    if (window.innerWidth >= 1024) {
      this.debouncedSubmit();
    }
  }

  debouncedSubmit() {
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
    this.debounceTimeout = setTimeout(() => this.submitFilters(), 300);
  }

  // Mobile "Apply" button. Submits the drawer's form; the frame navigation that
  // follows re-renders (and thereby closes) the drawer.
  submitForm(event) {
    this.changedForm = event.target.closest("form");
    this.submitFilters();
  }

  submitFilters() {
    const form = this.changedForm || this.element.querySelector("form");
    form?.requestSubmit();
  }

  handleKeydown(event) {
    if (!this.openValue) return;

    if (event.key === "Escape" || event.key === "Esc") {
      event.preventDefault();
      this.close();
      if (this.hasToggleTarget && this.toggleTarget.focus) {
        this.toggleTarget.focus();
      }
    }
  }

  handleClickOutside(event) {
    if (!this.openValue) return;

    if (
      this.hasSidebarTarget &&
      !this.sidebarTarget.contains(event.target) &&
      (!this.hasToggleTarget || !this.toggleTarget.contains(event.target)) &&
      (!this.hasOverlayTarget || !this.overlayTarget.contains(event.target))
    ) {
      this.close();
    }
  }

  updateSidebarState() {
    if (!this.hasSidebarTarget) return;

    if (this.openValue) {
      // Only apply modal-like behavior on mobile
      if (window.innerWidth < 1024) {
        document.body.classList.add("overflow-hidden");
        this.trapFocus();
      }
    } else {
      document.body.classList.remove("overflow-hidden");
      this.removeFocusTrap();
    }
  }

  setInitialSidebarState() {
    if (window.innerWidth >= 1024) {
      this.openValue = true;
    }
  }

  trapFocus() {
    if (!this.hasSidebarTarget) return;
    this.originalFocusElement = document.activeElement;
    this.sidebarTarget.setAttribute("tabindex", "-1");
    this.sidebarTarget.focus();
  }

  removeFocusTrap() {
    if (!this.hasSidebarTarget) return;
    this.sidebarTarget.removeAttribute("tabindex");
    if (this.originalFocusElement && this.originalFocusElement.focus) {
      this.originalFocusElement.focus();
    }
  }

  handleResize() {
    if (window.innerWidth >= 1024 && !this.openValue) {
      this.openValue = true;
      this.updateSidebarState();
    }

    if (window.innerWidth < 1024 && this.openValue) {
      this.openValue = false;
      this.updateSidebarState();
    }
  }

  resize() {
    this.handleResize();
  }
}

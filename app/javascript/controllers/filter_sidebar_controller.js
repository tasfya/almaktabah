import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "sidebar",
    "toggle",
    "overlay",
    "form",
    "checkbox",
    "clearButton",
    "submitButton",
    "checkboxToggle",
  ];

  static values = {
    open: { type: Boolean, default: false },
    applyFilters: { type: String, default: "" },
    loading: { type: String, default: "" },
    clearAll: { type: String, default: "" },
  };

  connect() {
    this.debounceTimeout = null;
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.boundHandleClickOutside = this.handleClickOutside.bind(this);
    this.boundHandleResize = this.handleResize.bind(this);

    document.addEventListener("keydown", this.boundHandleKeydown);
    document.addEventListener("click", this.boundHandleClickOutside);
    window.addEventListener("resize", this.boundHandleResize);

    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.addEventListener("change", () => {
        this.openValue = this.checkboxToggleTarget.checked;
        this.updateSidebarState();
      });
    }

    this.initializeFromUrl();
    this.setInitialSidebarState();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown);
    document.removeEventListener("click", this.boundHandleClickOutside);
    window.removeEventListener("resize", this.boundHandleResize);
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
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

  onCheckboxChange(event) {
    const checkbox = event.target;
    this.updateUrlParameter(checkbox.name, checkbox.value, checkbox.checked);
    this.debouncedSubmit(checkbox.closest("form"));
  }

  debouncedSubmit(form) {
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);

    this.debounceTimeout = setTimeout(() => {
      if (!form) {
        this.submitForm();
        return;
      }

      this.setLoadingState(true);

      const frameId = form.dataset.turboFrame;
      const frame = frameId && document.getElementById(frameId);

      if (frame) {
        const params = new URLSearchParams();

        form
          .querySelectorAll('input[type="checkbox"]:checked')
          .forEach((cb) => {
            if (cb.name && cb.value) params.append(cb.name, cb.value);
          });

        form.querySelectorAll('input[type="hidden"]').forEach((field) => {
          if (field.name && field.value) params.append(field.name, field.value);
        });

        frame.src = `${form.action}?${params.toString()}`;
      } else {
        form.requestSubmit();
      }

      setTimeout(() => this.setLoadingState(false), 1000);
    }, 300);
  }

  submitForm() {
    if (this.hasFormTarget) {
      this.setLoadingState(true);
      this.formTarget.requestSubmit();
      setTimeout(() => this.setLoadingState(false), 1000);
    }
  }

  clearAllFilters(event) {
    event.preventDefault();

    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        checkbox.checked = false;
      });
    }

    this.clearUrlParameters();
    this.submitForm();
  }

  removeFilter(event) {
    event.preventDefault();
    const chip = event.currentTarget;
    const filterName = chip.dataset.filterName;
    const filterValue = chip.dataset.filterValue;

    const checkbox = this.checkboxTargets.find(
      (cb) => cb.name === filterName && cb.value === filterValue
    );

    if (checkbox) {
      checkbox.checked = false;
      this.onCheckboxChange({ target: checkbox });
    }
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

  initializeFromUrl() {
    const urlParams = new URLSearchParams(window.location.search);

    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        const paramValues = urlParams.getAll(checkbox.name);
        checkbox.checked = paramValues.includes(checkbox.value);
      });
    }
  }

  updateUrlParameter(name, value, checked) {
    const url = new URL(window.location);
    const params = new URLSearchParams(url.search);
    const existingValues = params.getAll(name);

    if (checked && value) {
      if (!existingValues.includes(value)) {
        params.append(name, value);
      }
    } else if (value) {
      params.delete(name);
      existingValues
        .filter((v) => v !== value)
        .forEach((v) => params.append(name, v));
    }

    url.search = params.toString();
    window.history.replaceState({}, "", url);
  }

  clearUrlParameters() {
    const url = new URL(window.location);
    url.search = "";
    window.history.replaceState({}, "", url);
  }

  updateSidebarState() {
    if (!this.hasSidebarTarget) return;

    if (this.openValue) {
      document.body.classList.add("overflow-hidden");
      this.trapFocus();
    } else {
      document.body.classList.remove("overflow-hidden");
      this.removeFocusTrap();
    }
  }

  setInitialSidebarState() {
    if (window.innerWidth >= 1024) {
      this.openValue = true;
      this.updateSidebarState();
    }
  }

  setLoadingState(isLoading) {
    if (this.hasSubmitButtonTarget) {
      if (isLoading) {
        this.submitButtonTarget.disabled = true;
        this.submitButtonTarget.classList.add("loading");
        this.submitButtonTarget.innerHTML = `
          <span class="loading loading-spinner loading-sm"></span>
          ${this.loadingValue}
        `;
      } else {
        this.submitButtonTarget.disabled = false;
        this.submitButtonTarget.classList.remove("loading");
        this.submitButtonTarget.innerHTML = this.applyFiltersValue;
      }
    }

    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        checkbox.disabled = isLoading;
      });
    }
  }

  trapFocus() {
    if (!this.hasSidebarTarget) return;
    this.sidebarTarget.setAttribute("tabindex", "-1");
    this.sidebarTarget.focus();
    this.originalFocusElement = document.activeElement;
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

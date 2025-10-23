import { Controller } from "@hotwired/stimulus";

/**
 * FilterSidebarController manages the search filter sidebar state and interactions.
 *
 * Features:
 * - Mobile toggle functionality using DaisyUI drawer
 * - Form submission with debouncing
 * - URL parameter management for filter persistence
 * - Active filter chips display and removal
 * - Clear all filters functionality
 * - Keyboard navigation and accessibility
 * - Turbo integration for seamless updates
 */
export default class extends Controller {
  static targets = [
    "sidebar", // The sidebar drawer element
    "toggle", // Mobile toggle button
    "overlay", // Drawer overlay
    "form", // The filter form
    "checkbox", // All filter checkboxes
    "activeFilters", // Container for active filter chips
    "clearButton", // Clear all filters button
    "submitButton", // Form submit button
    "checkboxToggle", // DaisyUI drawer checkbox toggle
  ];

  static values = {
    open: { type: Boolean, default: false },
    debounceDelay: { type: Number, default: 300 },
  };

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.boundHandleClickOutside = this.handleClickOutside.bind(this);
    this.boundHandleResize = this.handleResize.bind(this);

    // Set up event listeners
    document.addEventListener("keydown", this.boundHandleKeydown);
    document.addEventListener("click", this.boundHandleClickOutside);
    window.addEventListener("resize", this.boundHandleResize);

    // Listen to checkbox toggle changes if available
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.addEventListener("change", () => {
        this.openValue = this.checkboxToggleTarget.checked;
        this.updateSidebarState();
      });
    }

    // Initialize URL parameters on page load
    this.initializeFromUrl();

    // Update active filters display
    this.updateActiveFilters();

    // Set initial sidebar state for mobile
    this.setInitialSidebarState();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown);
    document.removeEventListener("click", this.boundHandleClickOutside);
    window.removeEventListener("resize", this.boundHandleResize);
  }

  /**
   * Toggle sidebar open/closed state
   */
  toggle() {
    if (this.hasCheckboxToggleTarget) {
      // Use DaisyUI checkbox toggle
      this.checkboxToggleTarget.checked = !this.checkboxToggleTarget.checked;
      this.openValue = this.checkboxToggleTarget.checked;
    } else {
      // Fallback for non-DaisyUI implementation
      if (this.openValue) {
        this.close();
      } else {
        this.open();
      }
    }
  }

  /**
   * Open the sidebar
   */
  open() {
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.checked = true;
    }
    this.openValue = true;
    this.updateSidebarState();
    this.trapFocus();
  }

  /**
   * Close the sidebar
   */
  close() {
    if (this.hasCheckboxToggleTarget) {
      this.checkboxToggleTarget.checked = false;
    }
    this.openValue = false;
    this.updateSidebarState();
    this.removeFocusTrap();
  }

  /**
   * Handle checkbox changes with debounced form submission
   */
  onCheckboxChange(event) {
    const checkbox = event.target;

    // Update URL parameters immediately
    this.updateUrlParameter(
      checkbox.name,
      checkbox.checked ? checkbox.value : null
    );

    // Form submission
    this.submitForm();

    // Update active filters display
    this.updateActiveFilters();
  }

  /**
   * Handle form submission with Turbo
   */
  submitForm() {
    if (this.hasFormTarget) {
      // Show loading state
      this.setLoadingState(true);

      // Submit form with Turbo
      this.formTarget.requestSubmit();

      // Hide loading state after a short delay (Turbo will handle the actual update)
      setTimeout(() => {
        this.setLoadingState(false);
      }, 1000);
    }
  }

  /**
   * Clear all filters and reset the form
   */
  clearAllFilters(event) {
    event.preventDefault();

    // Uncheck all checkboxes
    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        checkbox.checked = false;
      });
    }

    // Clear URL parameters
    this.clearUrlParameters();

    // Submit the form to get unfiltered results
    this.submitForm();

    // Update active filters display
    this.updateActiveFilters();
  }

  /**
   * Remove individual filter by clicking on active filter chip
   */
  removeFilter(event) {
    event.preventDefault();
    const chip = event.currentTarget;
    const filterName = chip.dataset.filterName;
    const filterValue = chip.dataset.filterValue;

    // Find and uncheck the corresponding checkbox
    const checkbox = this.checkboxTargets.find(
      (cb) => cb.name === filterName && cb.value === filterValue
    );

    if (checkbox) {
      checkbox.checked = false;
      this.onCheckboxChange({ target: checkbox });
    }
  }

  /**
   * Handle keyboard navigation
   */
  handleKeydown(event) {
    if (!this.openValue) return;

    switch (event.key) {
      case "Escape":
      case "Esc":
        event.preventDefault();
        this.close();
        if (this.hasToggleTarget && this.toggleTarget.focus) {
          this.toggleTarget.focus();
        }
        break;
    }
  }

  /**
   * Handle clicks outside the sidebar to close it
   */
  handleClickOutside(event) {
    if (!this.openValue) return;

    // Check if click is outside the sidebar and not on the toggle button
    if (
      this.hasSidebarTarget &&
      !this.sidebarTarget.contains(event.target) &&
      (!this.hasToggleTarget || !this.toggleTarget.contains(event.target)) &&
      (!this.hasOverlayTarget || !this.overlayTarget.contains(event.target))
    ) {
      this.close();
    }
  }

  /**
   * Initialize form state from URL parameters on page load
   */
  initializeFromUrl() {
    const urlParams = new URLSearchParams(window.location.search);

    // Set checkbox states based on URL parameters
    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        const paramValues = urlParams.getAll(checkbox.name);
        checkbox.checked = paramValues.includes(checkbox.value);
      });
    }
  }

  /**
   * Update URL parameters when filters change
   */
  updateUrlParameter(name, value) {
    const url = new URL(window.location);
    const params = new URLSearchParams(url.search);

    if (value) {
      params.append(name, value);
    } else {
      // Remove all instances of this parameter
      params.delete(name);
    }

    // Update URL without triggering a page reload
    url.search = params.toString();
    window.history.replaceState({}, "", url);
  }

  /**
   * Clear all URL parameters
   */
  clearUrlParameters() {
    const url = new URL(window.location);
    url.search = "";
    window.history.replaceState({}, "", url);
  }

  /**
   * Update the visual state of the sidebar
   */
  updateSidebarState() {
    if (!this.hasSidebarTarget) return;

    // Prevent body scroll on mobile when drawer is open
    if (this.openValue) {
      document.body.classList.add("overflow-hidden");
    } else {
      document.body.classList.remove("overflow-hidden");
    }

    // Focus management
    if (this.openValue) {
      this.trapFocus();
    } else {
      this.removeFocusTrap();
    }
  }

  /**
   * Set initial sidebar state based on screen size
   */
  setInitialSidebarState() {
    // On desktop, keep sidebar open by default
    if (window.innerWidth >= 1024) {
      // lg breakpoint
      this.openValue = true;
      this.updateSidebarState();
    }
  }

  /**
   * Update active filter chips display
   */
  updateActiveFilters() {
    if (!this.hasActiveFiltersTarget) return;

    const activeFilters = this.getActiveFilters();

    if (activeFilters.length === 0) {
      this.activeFiltersTarget.innerHTML = `
        <div class="text-gray-500 text-sm">
          ${this.getTranslation("no_active_filters")}
        </div>
      `;

      if (this.hasClearButtonTarget) {
        this.clearButtonTarget.disabled = true;
        this.clearButtonTarget.classList.add(
          "opacity-50",
          "cursor-not-allowed"
        );
      }
    } else {
      this.activeFiltersTarget.innerHTML = activeFilters
        .map(
          (filter) => `
        <div class="badge badge-primary badge-lg gap-2 cursor-pointer hover:badge-secondary transition-colors"
             data-filter-name="${filter.name}"
             data-filter-value="${filter.value}"
             data-action="click->filter-sidebar#removeFilter">
          ${filter.label}
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
               class="inline-block w-4 h-4 stroke-current">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </div>
      `
        )
        .join("");

      if (this.hasClearButtonTarget) {
        this.clearButtonTarget.disabled = false;
        this.clearButtonTarget.classList.remove(
          "opacity-50",
          "cursor-not-allowed"
        );
      }
    }
  }

  /**
   * Get currently active filters
   */
  getActiveFilters() {
    const activeFilters = [];

    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        if (checkbox.checked) {
          activeFilters.push({
            name: checkbox.name,
            value: checkbox.value,
            label: this.getFilterLabel(checkbox),
          });
        }
      });
    }

    return activeFilters;
  }

  /**
   * Get human-readable label for a filter
   */
  getFilterLabel(checkbox) {
    // Try to get label from associated label element
    const label = document.querySelector(`label[for="${checkbox.id}"]`);
    if (label) {
      return label.textContent.trim();
    }

    // Fallback to value with title case
    return checkbox.value
      .split("_")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ");
  }

  /**
   * Set loading state during form submission
   */
  setLoadingState(isLoading) {
    if (this.hasSubmitButtonTarget) {
      if (isLoading) {
        this.submitButtonTarget.disabled = true;
        this.submitButtonTarget.classList.add("loading");
        this.submitButtonTarget.innerHTML = `
          <span class="loading loading-spinner loading-sm"></span>
          ${this.getTranslation("loading")}
        `;
      } else {
        this.submitButtonTarget.disabled = false;
        this.submitButtonTarget.classList.remove("loading");
        this.submitButtonTarget.innerHTML =
          this.getTranslation("apply_filters");
      }
    }

    // Disable checkboxes during loading
    if (this.hasCheckboxTarget) {
      this.checkboxTargets.forEach((checkbox) => {
        checkbox.disabled = isLoading;
      });
    }
  }

  /**
   * Focus management for accessibility
   */
  trapFocus() {
    if (!this.hasSidebarTarget) return;

    // Add tabindex to make sidebar focusable
    this.sidebarTarget.setAttribute("tabindex", "-1");
    this.sidebarTarget.focus();

    // Store original focus element
    this.originalFocusElement = document.activeElement;
  }

  /**
   * Remove focus trap
   */
  removeFocusTrap() {
    if (!this.hasSidebarTarget) return;

    this.sidebarTarget.removeAttribute("tabindex");

    // Restore focus to original element
    if (this.originalFocusElement && this.originalFocusElement.focus) {
      this.originalFocusElement.focus();
    }
  }

  /**
   * Get translation text (can be integrated with i18n)
   */
  getTranslation(key) {
    const translations = {
      no_active_filters: "No active filters",
      apply_filters: "Apply Filters",
      loading: "Loading...",
      clear_all: "Clear All Filters",
    };

    return translations[key] || key;
  }

  /**
   * Handle window resize events
   */
  handleResize() {
    // Auto-open sidebar on desktop if closed
    if (window.innerWidth >= 1024 && !this.openValue) {
      this.openValue = true;
      this.updateSidebarState();
    }

    // Auto-close sidebar on mobile if open
    if (window.innerWidth < 1024 && this.openValue) {
      this.openValue = false;
      this.updateSidebarState();
    }
  }

  /**
   * Public method for programmatic resize handling
   */
  resize() {
    this.handleResize();
  }
}

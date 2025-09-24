import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "switcher"];

  connect() {
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme) {
      document.documentElement.setAttribute("data-theme", savedTheme);
      this.selectTarget.value = savedTheme;
    }
  }

  changeTheme(event) {
    const selectedTheme = event.target.value;
    document.documentElement.setAttribute("data-theme", selectedTheme);
    localStorage.setItem("theme", selectedTheme);
  }

  hide() {
    this.switcherTarget.style.display = "none";
  }
}

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["contentType", "query"];

  navigate() {
    const path = this.contentTypeTarget.value;
    const query = this.queryTarget.value.trim();

    if (query) {
      window.location.href = `${path}?q=${encodeURIComponent(query)}`;
    } else {
      window.location.href = path;
    }
  }

  submit(event) {
    event.preventDefault();
    this.navigate();
  }
}

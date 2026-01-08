import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = ["contentType", "query"];

  navigate() {
    const path = this.contentTypeTarget.value;
    const query = this.queryTarget.value.trim();
    const url = query ? `${path}?q=${encodeURIComponent(query)}` : path;
    Turbo.visit(url);
  }

  submit(event) {
    event.preventDefault();
    this.navigate();
  }
}

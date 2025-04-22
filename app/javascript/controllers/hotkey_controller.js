import { Controller } from "@hotwired/stimulus"
import { install, uninstall } from "@github/hotkey"

export default class extends Controller {
  static targets = ["shortcut"]

  shortcutTargetConnected(target) {
    const shortcuts = target.getAttribute("aria-keyshortcuts").split(",")
    shortcuts.forEach(shortcut => {
      install(target, shortcut.trim())
    })
  }

  shortcutTargetDisconnected(target) {
    uninstall(target)
  }
}

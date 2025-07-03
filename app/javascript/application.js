import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

import NavigationController from "./controllers/navigation_controller"

import ClipboardController from "./controllers/clipboard_controller"
import PlayButtonController from "./controllers/play_button_controller"
import PlayerController from "./controllers/player_controller"

const application = Application.start()

application.register("navigation", NavigationController)
application.register("clipboard", ClipboardController)
application.register("play-button", PlayButtonController)
application.register("player", PlayerController)

application.debug = false
window.Stimulus = application
window.application = application

export { application }
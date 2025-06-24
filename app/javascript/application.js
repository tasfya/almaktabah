// Modern JavaScript application entry point using esbuild
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Import all Stimulus controllers manually
import AudioPlayerController from "./controllers/audio_player_controller"

// Start Stimulus application
const application = Application.start()

// Register controllers
application.register("audio-player", AudioPlayerController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application
window.application = application


export { application }

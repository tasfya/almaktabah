// Modern JavaScript application entry point using esbuild
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

application.debug = false
window.Stimulus = application
window.application = application

export { application }

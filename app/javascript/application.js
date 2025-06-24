// Modern JavaScript application entry point using esbuild
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
const application = Application.start()
export { application }

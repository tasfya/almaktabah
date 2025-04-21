// app/frontend/controllers/index.js
import { Application } from '@hotwired/stimulus'

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Auto-load all Stimulus controllers
const controllers = import.meta.glob('./**/*_controller.js', { eager: true })

for (const path in controllers) {
  const name = path
    .replace('./', '')
    .replace('_controller.js', '')
    .replace(/\//g, '--')
    .replace(/_/g, '-')
  
  application.register(name, controllers[path].default)
}

export { application }
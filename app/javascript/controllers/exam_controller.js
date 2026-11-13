import { Controller } from "@hotwired/stimulus"

// The open exam form. Keeps a draft of the answers in this browser (never on
// the server) so a reload, a trip back to the timeline or a sign-in bounce
// does not lose them; the result page clears it. Counts answered questions
// and names the unanswered ones before the single submit.
export default class extends Controller {
  static targets = ["question", "answered"]
  static values = { key: String, clear: Boolean, answeredTemplate: String, confirm: String, confirmUnanswered: String }

  connect() {
    if (this.clearValue) {
      this.write(null)
      return
    }
    this.restore()
    this.update()
  }

  change() {
    this.write(this.answers())
    this.update()
  }

  submit(event) {
    const missing = this.unanswered()
    this.questionTargets.forEach((question) => question.toggleAttribute("data-unanswered", missing.includes(question)))
    const message = missing.length === 0
      ? this.confirmValue
      : this.confirmUnansweredValue
          .replace("%{count}", missing.length)
          .replace("%{numbers}", missing.map((question) => question.dataset.number).join("، "))
    if (window.confirm(message)) return

    event.preventDefault()
    if (missing.length > 0) {
      missing[0].scrollIntoView({ block: "start" })
      missing[0].querySelector("input")?.focus({ preventScroll: true })
    }
  }

  update() {
    this.questionTargets.forEach((question) => {
      if (this.isAnswered(question)) question.removeAttribute("data-unanswered")
    })
    if (this.hasAnsweredTarget) {
      const answered = this.questionTargets.length - this.unanswered().length
      this.answeredTarget.textContent = this.answeredTemplateValue
        .replace("%{answered}", answered)
        .replace("%{total}", this.questionTargets.length)
    }
  }

  answers() {
    const answers = {}
    this.element.querySelectorAll("input[type=radio]:checked").forEach((input) => { answers[input.name] = input.value })
    return answers
  }

  restore() {
    const answers = this.read()
    if (!answers) return

    this.element.querySelectorAll("input[type=radio]").forEach((input) => {
      if (answers[input.name] === input.value) input.checked = true
    })
  }

  unanswered() {
    return this.questionTargets.filter((question) => !this.isAnswered(question))
  }

  isAnswered(question) {
    return question.querySelector("input[type=radio]:checked") !== null
  }

  read() {
    try {
      return JSON.parse(window.localStorage.getItem(this.keyValue))
    } catch {
      return null
    }
  }

  write(answers) {
    try {
      if (answers) window.localStorage.setItem(this.keyValue, JSON.stringify(answers))
      else window.localStorage.removeItem(this.keyValue)
    } catch {
      // Storage disabled or full: the form still works, without a draft.
    }
  }
}

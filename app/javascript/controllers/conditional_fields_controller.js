import { Controller } from "@hotwired/stimulus"

// Generic controller for showing/hiding fields based on radio/checkbox state
export default class extends Controller {
  static targets = ["content", "inverseContent", "mainContent", "trigger"]

  connect() {
    // Initialize visibility based on checked radio button state
    const checkedTrigger = this.triggerTargets.find(trigger => trigger.checked)
    if (checkedTrigger) {
      // If a radio is checked, determine which action to call
      const action = checkedTrigger.dataset.action
      if (action && action.includes("#show")) {
        this.show()
      } else if (action && action.includes("#hide")) {
        this.hide()
      }
    }
  }

  show() {
    this.mainContentTargets.forEach(target => target.classList.remove("fr-hidden"))
    this.contentTargets.forEach(target => target.classList.remove("fr-hidden"))
    this.inverseContentTargets.forEach(target => target.classList.add("fr-hidden"))
  }

  hide() {
    this.mainContentTargets.forEach(target => target.classList.remove("fr-hidden"))
    this.contentTargets.forEach(target => target.classList.add("fr-hidden"))
    this.inverseContentTargets.forEach(target => target.classList.remove("fr-hidden"))
  }
}

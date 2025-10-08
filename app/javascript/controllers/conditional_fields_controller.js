import { Controller } from "@hotwired/stimulus"

// Generic controller for showing/hiding fields based on radio/checkbox state
export default class extends Controller {
  static targets = ["content", "inverseContent"]

  show() {
    this.contentTargets.forEach(target => target.classList.remove("fr-hidden"))
    this.inverseContentTargets.forEach(target => target.classList.add("fr-hidden"))
  }

  hide() {
    this.contentTargets.forEach(target => target.classList.add("fr-hidden"))
    this.inverseContentTargets.forEach(target => target.classList.remove("fr-hidden"))
  }
}

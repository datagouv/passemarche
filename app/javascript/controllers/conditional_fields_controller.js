import { Controller } from "@hotwired/stimulus"

// Generic controller for showing/hiding fields based on radio/checkbox state
export default class extends Controller {
  static targets = ["content"]

  show() {
    this.contentTarget.classList.remove("fr-hidden")
  }

  hide() {
    this.contentTarget.classList.add("fr-hidden")
  }
}

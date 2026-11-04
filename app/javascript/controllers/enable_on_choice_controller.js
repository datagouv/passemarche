import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "submitButton"]

  connect() {
    this._update()
  }

  toggle() {
    this._update()
  }

  _update() {
    const hasChoice = this.choiceTargets.some(choice => choice.checked)
    this.submitButtonTargets.forEach(btn => { btn.disabled = !hasChoice })
  }
}

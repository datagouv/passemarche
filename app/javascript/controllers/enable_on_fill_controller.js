import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitButton"]

  connect() {
    this._update()
  }

  toggle() {
    this._update()
  }

  _update() {
    const allFilled = this.inputTargets.every(input => input.value.trim().length > 0)
    this.submitButtonTargets.forEach(btn => { btn.disabled = !allFilled })
  }
}

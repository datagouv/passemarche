import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitButton"]

  connect() {
    this._updateSubmitButtonState()
  }

  validateInput() {
    this._updateSubmitButtonState()
  }

  _updateSubmitButtonState() {
    const hasValidInput = this.inputTargets.some(input => {
      const value = input.value.trim()
      return value.length > 0
    })
    
    if (hasValidInput) {
      this._enableSubmit()
    } else {
      this._disableSubmit()
    }
  }

  _enableSubmit() {
    this.submitButtonTarget.disabled = false
  }

  _disableSubmit() {
    this.submitButtonTarget.disabled = true
  }
}
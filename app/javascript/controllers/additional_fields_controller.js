import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["accordion", "submitButton", "yesOption", "noOption"]

  connect() {
    this._hideAccordion()
    this._disableSubmit()
  }

  showAdditionalFieldsAndEnableSubmit() {
    this._showAccordion()
    this._enableSubmit()
  }

  hideAdditionalFieldsAndEnableSubmit() {
    this._hideAccordion()
    this._clearAllSelections()
    this._enableSubmit()
  }

  _showAccordion() {
    this.accordionTarget.classList.remove("fr-hidden")
  }

  _hideAccordion() {
    this.accordionTarget.classList.add("fr-hidden")
  }

  _enableSubmit() {
    this.submitButtonTarget.disabled = false
  }

  _disableSubmit() {
    this.submitButtonTarget.disabled = true
  }

  _clearAllSelections() {
    const checkboxes = this.accordionTarget.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.checked = false
    })
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["accordion", "submitButton", "yesOption", "noOption"]
  static values = { alreadyCompleted: Boolean }

  connect() {
    this._boundHandleCheckboxChange = this._handleCheckboxChange.bind(this)
    this._initializeState()
  }

  showAdditionalFieldsAndEnableSubmit() {
    this._showAccordion()
    this._disableSubmit()
    this._addCheckboxListeners()
    this._handleCheckboxChange()
  }

  hideAdditionalFieldsAndEnableSubmit() {
    this._hideAccordion()
    this._clearAllSelections()
    this._removeCheckboxListeners()
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

  _addCheckboxListeners() {
    const checkboxes = this.accordionTarget.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.addEventListener('change', this._boundHandleCheckboxChange)
    })
  }

  _removeCheckboxListeners() {
    const checkboxes = this.accordionTarget.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.removeEventListener('change', this._boundHandleCheckboxChange)
    })
  }

  _handleCheckboxChange() {
    const checkboxes = this.accordionTarget.querySelectorAll('input[type="checkbox"]')
    const hasCheckedBoxes = Array.from(checkboxes).some(checkbox => checkbox.checked)

    if (hasCheckedBoxes) {
      this._enableSubmit()
    } else {
      this._disableSubmit()
    }
  }

  _initializeState() {
    const checkboxes = this.accordionTarget.querySelectorAll('input[type="checkbox"]')
    const hasPreCheckedBoxes = Array.from(checkboxes).some(checkbox => checkbox.checked)

    if (hasPreCheckedBoxes) {
      // Public market already has additional fields selected
      this.yesOptionTarget.checked = true
      this._showAccordion()
      this._addCheckboxListeners()
      this._handleCheckboxChange()
    } else if (this.alreadyCompletedValue) {
      // Buyer already went through this step and selected no fields
      this.noOptionTarget.checked = true
      this._hideAccordion()
      this._enableSubmit()
    } else {
      // No selection made yet
      this._hideAccordion()
      this._disableSubmit()
    }
  }
}

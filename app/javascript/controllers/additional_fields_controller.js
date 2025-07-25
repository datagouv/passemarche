import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["accordion", "submitButton", "yesOption", "noOption"]

  connect() {
    // Initially hide accordion and disable submit button
    this.hideAccordion()
    this.disableSubmit()
  }

  // Called when user selects "Yes" to wanting additional fields
  selectYes() {
    this.showAccordion()
    this.enableSubmit()
  }

  // Called when user selects "No" to additional fields
  selectNo() {
    this.hideAccordion()
    this.clearAllSelections()
    this.enableSubmit()
  }

  showAccordion() {
    this.accordionTarget.classList.remove("fr-hidden")
  }

  hideAccordion() {
    this.accordionTarget.classList.add("fr-hidden")
  }

  enableSubmit() {
    this.submitButtonTarget.disabled = false
  }

  disableSubmit() {
    this.submitButtonTarget.disabled = true
  }

  clearAllSelections() {
    // Uncheck all checkboxes in the accordion
    const checkboxes = this.accordionTarget.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.checked = false
    })
  }
}
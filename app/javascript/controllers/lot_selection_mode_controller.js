import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "submitButton", "section", "form", "removalModal", "removalModalTitle"]
  static values = {
    requiresBoth: Boolean,
    confirmRemoval: Boolean,
    titleSingle: String,
    titleMultiple: String
  }

  connect() {
    this.recompute()
  }

  applyBulk(event) {
    const mode = event.target.value
    if (!mode) return

    const section = event.target.closest("[data-lot-selection-mode-target='section']")
    section.querySelectorAll("[data-lot-selection-mode-target='radio']").forEach(radio => {
      if (radio.value === mode) radio.checked = true
    })

    this.recompute()
  }

  recompute() {
    const checked = this.radioTargets.filter(radio => radio.checked)
    const hasGroupement = checked.some(radio => radio.value === "groupement")
    const hasSolo = checked.some(radio => radio.value === "solo")

    const complete = this.requiresBothValue ? hasSolo && hasGroupement : hasGroupement

    this.submitButtonTargets.forEach(btn => { btn.disabled = !complete })
  }

  handleSubmit(event) {
    if (this.pendingConfirmation) {
      this.pendingConfirmation = false
      return
    }

    const removedLotNumbers = this.lotsRemovedFromGroupement()
    if (!this.confirmRemovalValue || removedLotNumbers.length === 0) return

    event.preventDefault()
    this.openRemovalModal(removedLotNumbers)
  }

  lotsRemovedFromGroupement() {
    return this.radioTargets
      .filter(radio => radio.value === "groupement" && radio.dataset.initiallyGroupement === "true" && !radio.checked)
      .map(radio => Number(radio.dataset.lotNumber))
      .sort((a, b) => a - b)
  }

  openRemovalModal(lotNumbers) {
    this.removalModalTitleTarget.textContent = lotNumbers.length === 1
      ? this.titleSingleValue.replace("%{number}", lotNumbers[0])
      : this.titleMultipleValue.replace("%{numbers}", lotNumbers.join(", "))

    this.removalModalTarget.showModal()
  }

  closeRemovalModal() {
    this.removalModalTarget.close()
  }

  clickRemovalModalBackdrop(event) {
    if (event.target === this.removalModalTarget) this.closeRemovalModal()
  }

  confirmRemoval() {
    if (this.pendingConfirmation) return

    this.pendingConfirmation = true
    this.removalModalTarget.close()
    this.formTarget.requestSubmit()
  }
}

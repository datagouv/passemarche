import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "submitButton", "section"]
  static values = { requiresBoth: Boolean }

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
}

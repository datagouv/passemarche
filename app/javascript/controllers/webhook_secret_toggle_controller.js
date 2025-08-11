import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "button", "icon"]

  connect() {
    this.isVisible = false
  }

  toggle() {
    this.isVisible = !this.isVisible
    
    if (this.isVisible) {
      // Show real value
      this.fieldTarget.value = this.fieldTarget.dataset.webhookSecretToggleRealValue
      this.iconTarget.className = "fr-icon-eye-off-line"
      this.buttonTarget.title = "Masquer le secret"
    } else {
      // Show masked value
      this.fieldTarget.value = this.fieldTarget.dataset.webhookSecretToggleMaskedValue
      this.iconTarget.className = "fr-icon-eye-line"
      this.buttonTarget.title = "Afficher le secret"
    }
  }
}
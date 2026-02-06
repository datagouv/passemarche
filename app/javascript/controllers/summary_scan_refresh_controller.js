import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 } // 5 secondes par défaut
  }

  connect() {
    // Vérifier s'il y a des badges "scanning"
    const scanningBadges = this.element.querySelectorAll('.fr-badge--security-scanning')

    if (scanningBadges.length > 0) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollingTimer = setInterval(() => {
      this.checkAndRefresh()
    }, this.intervalValue)
  }

  stopPolling() {
    if (this.pollingTimer) {
      clearInterval(this.pollingTimer)
      this.pollingTimer = null
    }
  }

  checkAndRefresh() {
    // Vérifier s'il reste des badges "scanning"
    const scanningBadges = this.element.querySelectorAll('.fr-badge--security-scanning')

    if (scanningBadges.length > 0) {
      window.location.reload()
    } else {
      this.stopPolling()
    }
  }
}

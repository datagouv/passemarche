import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 2000 }
  }

  connect() {
    if (!this.hasUrlValue) return

    const scanningBadges = this.element.querySelectorAll('.fr-badge--security-scanning')

    if (scanningBadges.length > 0) {
      console.log(`${scanningBadges.length} fichier(s) en cours de scan, auto-refresh activé`)
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollingTimer = setInterval(() => this.checkStatus(), this.intervalValue)
  }

  stopPolling() {
    if (this.pollingTimer) {
      clearInterval(this.pollingTimer)
      this.pollingTimer = null
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { 'Accept': 'application/json' }
      })

      if (!response.ok) return

      const data = await response.json()

      this.updateBadges(data.blob_states)

      if (data.scans_complete) {
        this.stopPolling()
      }
    } catch (error) {
      console.error('Scan status check error:', error)
    }
  }

  updateBadges(blobStates) {
    if (!blobStates) return

    blobStates.forEach(({ blob_id, badge_html }) => {
      const badge = this.element.querySelector(`[data-scan-badge-blob-id="${blob_id}"]`)
      if (!badge) return

      const template = document.createElement('template')
      template.innerHTML = badge_html.trim()
      const newBadge = template.content.firstChild

      if (badge.dataset.scanState !== newBadge.dataset.scanState) {
        badge.replaceWith(newBadge)
      }
    })
  }
}

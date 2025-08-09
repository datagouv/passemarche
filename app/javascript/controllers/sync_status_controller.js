import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, redirectUrl: String }

  connect() {
    const status = this.element.dataset.status
    if (status === 'sync_completed') {
      this.scheduleRedirect()
    } else if (status === 'sync_pending' || status === 'sync_processing') {
      this.startPolling()
    }
  }

  disconnect() {
    clearInterval(this.pollInterval)
  }

  startPolling() {
    this.pollInterval = setInterval(() => this.checkStatus(), 2000)
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue, { headers: { 'Accept': 'application/json' } })
      const data = await response.json()

      if (data.sync_status === 'sync_completed' || data.sync_status === 'sync_failed') {
        location.reload()
      }
    } catch (error) {
      console.error('Sync status error:', error)
    }
  }

  scheduleRedirect() {
    if (this.redirectUrlValue) {
      setTimeout(() => window.location.href = this.redirectUrlValue, 3000)
    }
  }
}

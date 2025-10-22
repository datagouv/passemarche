import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["loader"]

  connect() {
    const status = this.element.dataset.status
    // Only start polling if explicitly set to pending/processing, or if no status (for API fetch polling)
    if (!status || status === 'sync_pending' || status === 'sync_processing') {
      this.previousData = null
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
      console.log('Polling...', this.urlValue)
      const response = await fetch(this.urlValue, { headers: { 'Accept': 'application/json' } })
      const data = await response.json()

      console.log('Received data:', data)

      // Check if data has changed
      const currentDataString = JSON.stringify(data)
      console.log('Previous:', this.previousData)
      console.log('Current:', currentDataString)
      console.log('Are they different?', this.previousData !== currentDataString)

      // Check if data changed (and previousData was already set)
      if (this.previousData && this.previousData !== currentDataString) {
        console.log('Status changed! Reloading...')
        this.triggerReload()
        return
      }

      // Check if all APIs are completed on first load
      if (!this.previousData && data.api_fetch_status) {
        const allCompleted = Object.values(data.api_fetch_status).every(status =>
          status.status === 'completed' || status.status === 'failed'
        )
        if (allCompleted) {
          console.log('All APIs already completed on first load! Reloading...')
          this.triggerReload()
          return
        }
      }

      this.previousData = currentDataString

      // Legacy check for sync_status field
      if (data.sync_status === 'sync_completed' || data.sync_status === 'sync_failed') {
        this.triggerReload()
      }
    } catch (error) {
      console.error('Sync status error:', error)

      if (this.hasLoaderTarget) {
        this.loaderTarget.style.opacity = '0.5'
        this.loaderTarget.setAttribute('aria-label', 'Erreur de connexion, vérification...')
      }
    }
  }

  triggerReload() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.animationPlayState = 'paused'
    }
    setTimeout(() => location.reload(), 300)
  }

}

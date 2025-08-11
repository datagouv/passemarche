import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, redirectUrl: String }
  static targets = ["loader"]

  connect() {
    const status = this.element.dataset.status
    if (status === 'sync_pending' || status === 'sync_processing') {
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
        // Stop the loader animation before reloading
        if (this.hasLoaderTarget) {
          this.loaderTarget.style.animationPlayState = 'paused'
        }
        
        // Smooth transition before reload
        setTimeout(() => location.reload(), 300)
      }
    } catch (error) {
      console.error('Sync status error:', error)
      
      // Show error state on loader if connection fails
      if (this.hasLoaderTarget) {
        this.loaderTarget.style.opacity = '0.5'
        this.loaderTarget.setAttribute('aria-label', 'Erreur de connexion, vérification...')
      }
    }
  }

}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["loader", "continueButton"]

  async connect() {
    const status = this.element.dataset.status
    this.shouldPoll = true

    // Only start polling if explicitly set to pending/processing, or if no status (for API fetch polling)
    if (!status || status === 'sync_pending' || status === 'sync_processing') {
      this.previousData = null
      // Check initial button state immediately to see if we need to poll
      await this.checkStatus()
      // Only start polling if APIs aren't already done
      if (this.shouldPoll) {
        this.startPolling()
      }
    }
  }

  disconnect() {
    clearInterval(this.pollInterval)
  }

  startPolling() {
    this.pollInterval = setInterval(() => this.checkStatus(), 2000)
  }

  stopPolling() {
    this.shouldPoll = false
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue, { headers: { 'Accept': 'application/json' } })
      const data = await response.json()

      // Check if data has changed
      const currentDataString = JSON.stringify(data)

      // Check if all APIs are completed
      const allCompleted = data.api_fetch_status && Object.values(data.api_fetch_status).every(status =>
        status.status === 'completed' || status.status === 'failed'
      )

      // Stop polling if all APIs are done
      if (allCompleted) {
        this.stopPolling()
      }

      // Check if this is the first check
      const isFirstCheck = !this.previousData

      // Update previousData before checking for changes
      const hasChanged = this.previousData && this.previousData !== currentDataString
      this.previousData = currentDataString

      // If data changed after first check, reload to update UI
      if (hasChanged) {
        this.triggerReload()
        return
      }

      // On first check with all complete: only reload if UI needs updating
      // We check the initial_state data attribute to see if server already knew APIs were done
      if (isFirstCheck && allCompleted) {
        const initialState = this.hasContinueButtonTarget ?
                             this.continueButtonTarget.dataset.initialState :
                             null

        // Only reload if server thought APIs were not done (initial state was "disabled")
        if (initialState === 'disabled') {
          this.triggerReload()
          return
        }
      }

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

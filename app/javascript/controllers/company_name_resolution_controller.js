import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, pending: Boolean }

  connect() {
    if (this.pendingValue) {
      this.pollInterval = setInterval(() => this.checkStatus(), 2000)
    }
  }

  disconnect() {
    clearInterval(this.pollInterval)
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      const data = await response.json()

      if (!data.company_names_pending) {
        clearInterval(this.pollInterval)
        location.reload()
      }
    } catch (error) {
      console.error("Company name resolution polling error:", error)
    }
  }
}

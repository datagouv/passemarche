import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "panel", "radio"]
  static values = { updateUrl: String }

  toggle() {
    const anyChecked = this.checkboxTargets.some(cb => cb.checked)
    this.panelTarget.style.display = anyChecked ? "block" : "none"
    if (!anyChecked) this.#resetRadios()
  }

  cancel() {
    this.checkboxTargets.forEach(cb => { cb.checked = false })
    this.#resetRadios()
    this.panelTarget.style.display = "none"
  }

  async apply() {
    const selectedRadio = this.radioTargets.find(r => r.checked)
    if (!selectedRadio) return

    const lotIds = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    const body = new FormData()
    body.append("market_type_id", selectedRadio.value)
    lotIds.forEach(id => body.append("lot_ids[]", id))

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(this.updateUrlValue, {
      method: "PATCH",
      headers: { "X-CSRF-Token": csrfToken, "Accept": "text/vnd.turbo-stream.html" },
      body
    })

    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
      this.cancel()
    } else {
      this.cancel()
    }
  }

  #resetRadios() {
    this.radioTargets.forEach(r => { r.checked = false })
  }
}

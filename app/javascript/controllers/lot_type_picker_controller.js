import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "checkboxColumn", "panel", "radio", "editButton", "toggleAllButton"]
  static values = { updateUrl: String }

  enableEdit() {
    this.checkboxColumnTargets.forEach(el => { el.style.display = "" })
    this.editButtonTarget.style.display = "none"
    this.toggleAllButtonTarget.style.display = ""
    this.panelTarget.style.display = "block"
  }

  toggle() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    this.toggleAllButtonTarget.textContent = allChecked
      ? this.toggleAllButtonTarget.dataset.deselectText
      : this.toggleAllButtonTarget.dataset.selectText
  }

  toggleAll() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    this.checkboxTargets.forEach(cb => { cb.checked = !allChecked })
    this.toggle()
  }

  cancel() {
    this.checkboxTargets.forEach(cb => { cb.checked = false })
    this.#resetRadios()
    this.panelTarget.style.display = "none"
    this.checkboxColumnTargets.forEach(el => { el.style.display = "none" })
    this.editButtonTarget.style.display = ""
    this.toggleAllButtonTarget.style.display = "none"
    this.toggleAllButtonTarget.textContent = this.toggleAllButtonTarget.dataset.selectText
  }

  async apply() {
    const selectedRadio = this.radioTargets.find(r => r.checked)
    if (!selectedRadio) return

    const lotIds = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    if (lotIds.length === 0) return

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

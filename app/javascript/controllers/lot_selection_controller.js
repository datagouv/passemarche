import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "checkboxGroup", "submitButton", "selectAllButton", "noLotsText", "progressCard", "selectedLotsCount", "limitError"]
  static values = { limit: Number, storageKey: String }

  connect() {
    this._restoreSelectionFromStorage()
    this._update()
  }

  toggle(event) {
    const limit = this._limit()
    const checked = this.checkboxTargets.filter(cb => cb.checked)

    if (event.target.checked && checked.length > limit) {
      event.target.checked = false
    }

    this._update()
  }

  selectAll() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const limitReached = checked.length >= this._limit()
    const allChecked = checked.length === this.checkboxTargets.length

    if (allChecked || limitReached) {
      this.checkboxTargets.forEach(cb => { cb.checked = false })
    } else {
      const limit = this._limit()
      let selected = checked.length
      this.checkboxTargets.forEach(cb => {
        if (!cb.checked && selected < limit) {
          cb.checked = true
          selected++
        }
      })
    }
    this._update()
  }

  _limit() {
    return this.hasLimitValue && this.limitValue > 0 ? this.limitValue : Infinity
  }

  _update() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const hasChecked = checked.length > 0
    const limitReached = checked.length >= this._limit()
    this.submitButtonTargets.forEach(btn => { btn.disabled = !hasChecked })

    this.checkboxTargets.forEach((cb, i) => {
      const isUnchecked = !cb.checked
      cb.disabled = isUnchecked && limitReached
      if (this.hasCheckboxGroupTarget) {
        this.checkboxGroupTargets[i].classList.toggle("fr-checkbox-group--disabled", isUnchecked && limitReached)
      }
    })

    if (this.hasLimitErrorTarget) {
      this.limitErrorTarget.hidden = !limitReached
    }

    if (this.hasSelectAllButtonTarget) {
      const allSelected = checked.length === this.checkboxTargets.length || limitReached
      this.selectAllButtonTarget.textContent = allSelected
        ? this.selectAllButtonTarget.dataset.deselectText || "Tout désélectionner"
        : this.selectAllButtonTarget.dataset.selectText || "Tout sélectionner"
    }

    if (this.hasNoLotsTextTarget) {
      this.noLotsTextTarget.hidden = hasChecked
    }

    if (this.hasProgressCardTarget) {
      this.progressCardTarget.hidden = !hasChecked
    }

    if (this.hasSelectedLotsCountTarget && hasChecked) {
      const template = checked.length === 1
        ? this.selectedLotsCountTarget.dataset.one
        : this.selectedLotsCountTarget.dataset.other
      this.selectedLotsCountTarget.textContent = template.replace('%{count}', checked.length)
    }

    this._persistSelection(checked)
  }

  _restoreSelectionFromStorage() {
    if (!this.hasStorageKeyValue) {
      return
    }

    const raw = localStorage.getItem(this.storageKeyValue)
    if (!raw) {
      return
    }

    try {
      const selectedLotIds = JSON.parse(raw)
      if (!Array.isArray(selectedLotIds)) {
        return
      }

      const selectedSet = new Set(selectedLotIds.map(String))
      this.checkboxTargets.forEach((checkbox) => {
        checkbox.checked = selectedSet.has(String(checkbox.value))
      })
    } catch {
      localStorage.removeItem(this.storageKeyValue)
    }
  }

  _persistSelection(checkedCheckboxes) {
    if (!this.hasStorageKeyValue) {
      return
    }

    const selectedLotIds = checkedCheckboxes.map(checkbox => String(checkbox.value))
    localStorage.setItem(this.storageKeyValue, JSON.stringify(selectedLotIds))
  }
}

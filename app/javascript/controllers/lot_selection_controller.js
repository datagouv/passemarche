import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "checkboxGroup", "submitButton", "selectAllButton",
                    "noLotsText", "selectedLotsTags", "limitError"]
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

  selectAll(event) {
    const button = event.currentTarget
    const groupCheckboxes = this._checkboxesForButton(button)
    const checked = groupCheckboxes.filter(cb => cb.checked)
    const limit = this._limit()
    const allChecked = checked.length === groupCheckboxes.length
    const limitReached = this.checkboxTargets.filter(cb => cb.checked).length >= limit

    if (allChecked || limitReached) {
      groupCheckboxes.forEach(cb => { cb.checked = false })
    } else {
      let totalSelected = this.checkboxTargets.filter(cb => cb.checked).length
      groupCheckboxes.forEach(cb => {
        if (!cb.checked && totalSelected < limit) {
          cb.checked = true
          totalSelected++
        }
      })
    }
    this._update()
  }

  _limit() {
    return this.hasLimitValue && this.limitValue > 0 ? this.limitValue : Infinity
  }

  _checkboxesForButton(button) {
    const group = button.closest("[data-lot-selection-group]")
    if (!group) return this.checkboxTargets
    return Array.from(group.querySelectorAll("[data-lot-selection-target='checkbox']"))
  }

  _update() {
    const allChecked = this.checkboxTargets.filter(cb => cb.checked)
    const hasChecked = allChecked.length > 0
    const limitReached = allChecked.length >= this._limit()

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

    this._updateSelectAllButtons()
    this._renderSelectedLotsTags(allChecked)
    this._persistSelection(allChecked)
  }

  _updateSelectAllButtons() {
    this.selectAllButtonTargets.forEach(button => {
      const groupCheckboxes = this._checkboxesForButton(button)
      const groupChecked = groupCheckboxes.filter(cb => cb.checked)
      const allGroupSelected = groupChecked.length === groupCheckboxes.length && groupCheckboxes.length > 0
      button.textContent = allGroupSelected
        ? button.dataset.deselectText || "Tout désélectionner"
        : button.dataset.selectText || "Tout sélectionner"
    })
  }

  _renderSelectedLotsTags(checked) {
    if (!this.hasNoLotsTextTarget && !this.hasSelectedLotsTagsTarget) return

    if (this.hasNoLotsTextTarget) {
      this.noLotsTextTarget.hidden = checked.length > 0
    }

    if (this.hasSelectedLotsTagsTarget) {
      this.selectedLotsTagsTarget.replaceChildren(
        ...checked.map(cb => {
          const span = document.createElement("span")
          span.className = "fr-tag"
          span.style.background = "white"
          span.textContent = cb.dataset.lotName || ""
          return span
        })
      )
    }
  }

  _restoreSelectionFromStorage() {
    if (!this.hasStorageKeyValue) return

    const raw = localStorage.getItem(this.storageKeyValue)
    if (!raw) return

    try {
      const selectedLotIds = JSON.parse(raw)
      if (!Array.isArray(selectedLotIds)) return

      const selectedSet = new Set(selectedLotIds.map(String))
      this.checkboxTargets.forEach((checkbox) => {
        checkbox.checked = selectedSet.has(String(checkbox.value))
      })
    } catch {
      localStorage.removeItem(this.storageKeyValue)
    }
  }

  _persistSelection(checkedCheckboxes) {
    if (!this.hasStorageKeyValue) return

    const selectedLotIds = checkedCheckboxes.map(checkbox => String(checkbox.value))
    localStorage.setItem(this.storageKeyValue, JSON.stringify(selectedLotIds))
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "checkboxGroup", "submitButton", "selectAllButton",
                    "noLotsText", "selectedLotsTags", "selectedLotsCount", "limitError"]
  static values = { limit: Number, storageKey: String }

  connect() {
    this._tagCache = new Map()
    this._restoreSelectionFromStorage()
    this._update()
  }

  disconnect() {
    this._tagCache = null
  }

  toggle(event) {
    const limit = this._limit()
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (event.target.checked && checkedCount > limit) {
      event.target.checked = false
    }

    this._update()
  }

  selectAll(event) {
    const button = event.currentTarget
    const groupCheckboxes = this._checkboxesForButton(button)
    const allChecked = groupCheckboxes.every(cb => cb.checked)
    const limit = this._limit()
    const totalSelected = this.checkboxTargets.filter(cb => cb.checked).length
    const limitReached = totalSelected >= limit

    if (allChecked || limitReached) {
      groupCheckboxes.forEach(cb => { cb.checked = false })
    } else {
      let count = totalSelected
      groupCheckboxes.forEach(cb => {
        if (!cb.checked && count < limit) {
          cb.checked = true
          count++
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
    const prevLimitReached = this._limitReached

    this.submitButtonTargets.forEach(btn => { btn.disabled = !hasChecked })

    if (limitReached !== prevLimitReached) {
      this._limitReached = limitReached
      this.checkboxTargets.forEach((cb, i) => {
        const shouldDisable = !cb.checked && limitReached
        cb.disabled = shouldDisable
        if (this.hasCheckboxGroupTarget) {
          this.checkboxGroupTargets[i].classList.toggle("fr-checkbox-group--disabled", shouldDisable)
        }
      })
    }

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
      const allGroupSelected = groupCheckboxes.length > 0 && groupCheckboxes.every(cb => cb.checked)
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

    if (this.hasSelectedLotsCountTarget) {
      this.selectedLotsCountTarget.textContent = checked.length > 0 ? `(${checked.length})` : ""
    }

    if (!this.hasSelectedLotsTagsTarget) return

    const threshold = 5
    const checkedIds = new Set(checked.map(cb => cb.value))

    for (const id of this._tagCache.keys()) {
      if (!checkedIds.has(id)) this._tagCache.delete(id)
    }

    const prevIds = this._lastCheckedIds
    const nextIds = checked.map(cb => cb.value).join(",")
    this._lastCheckedIds = nextIds

    let cacheChanged = false
    const tags = checked.map(cb => {
      if (this._tagCache.has(cb.value)) {
        const span = this._tagCache.get(cb.value)
        span.style.display = ""
        return span
      }

      const span = document.createElement("span")
      span.className = "fr-tag"
      span.style.background = "white"
      const name = cb.dataset.lotName || ""
      const type = cb.dataset.lotType
      span.textContent = type ? `${name} - ${type}` : name
      this._tagCache.set(cb.value, span)
      cacheChanged = true
      return span
    })

    if (prevIds === nextIds && !cacheChanged) return

    const showMoreLabel = this.element.dataset.lotSelectionShowMoreLabel || "Voir tous les lots"
    const showLessLabel = this.element.dataset.lotSelectionShowLessLabel || "Réduire la liste"
    const children = this._buildCollapsibleList({ items: tags, threshold, showMoreLabel, showLessLabel })

    this.selectedLotsTagsTarget.replaceChildren(...children)
  }

  _restoreSelectionFromStorage() {
    if (!this.hasStorageKeyValue) return

    const raw = localStorage.getItem(this.storageKeyValue)
    if (!raw) return

    try {
      const selectedLotIds = JSON.parse(raw)
      if (!Array.isArray(selectedLotIds)) return

      const selectedSet = new Set(selectedLotIds.map(String))
      this.checkboxTargets.forEach(checkbox => {
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

  _buildCollapsibleList({ items, threshold, showMoreLabel, showLessLabel }) {
    if (items.length <= threshold) return items

    let expanded = false
    const hiddenItems = items.slice(threshold)
    hiddenItems.forEach(el => { el.style.display = "none" })

    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "collapsible-list__toggle"

    const updateLabel = () => {
      const icon = document.createElement("span")
      icon.setAttribute("aria-hidden", "true")
      icon.className = expanded ? "fr-icon-arrow-up-s-line fr-mr-1w" : "fr-icon-arrow-down-s-line fr-mr-1w"
      const text = document.createElement("span")
      text.textContent = expanded ? showLessLabel : showMoreLabel
      btn.setAttribute("aria-expanded", String(expanded))
      btn.replaceChildren(icon, text)
    }

    btn.addEventListener("click", () => {
      expanded = !expanded
      hiddenItems.forEach(el => { el.style.display = expanded ? "" : "none" })
      updateLabel()
    })

    updateLabel()

    const wrapper = document.createElement("div")
    wrapper.className = "collapsible-list__toggle-wrapper collapsible-list__toggle-wrapper--left"
    wrapper.appendChild(btn)

    return [...items, wrapper]
  }
}

import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['item', 'toggle']
  static values = {
    threshold: { type: Number, default: 5 },
    showMore: String,
    showLess: String
  }

  connect () {
    if (this.itemTargets.length <= this.thresholdValue) return

    this.itemTargets.slice(this.thresholdValue).forEach(el => { el.style.display = 'none' })
    this.toggleTarget.hidden = false
    this.expanded = false
    this._updateToggleLabel()
  }

  toggle () {
    this.expanded = !this.expanded
    this.itemTargets.slice(this.thresholdValue).forEach(el => {
      el.style.display = this.expanded ? '' : 'none'
    })
    this._updateToggleLabel()
  }

  _updateToggleLabel () {
    const icon = document.createElement('span')
    icon.setAttribute('aria-hidden', 'true')
    icon.className = this.expanded
      ? 'fr-icon-arrow-up-s-line fr-mr-1w'
      : 'fr-icon-arrow-down-s-line fr-mr-1w'

    const text = document.createElement('span')
    text.textContent = this.expanded ? this.showLessValue : this.showMoreValue
    this.toggleTarget.setAttribute('aria-expanded', String(this.expanded))
    this.toggleTarget.replaceChildren(icon, text)
  }
}

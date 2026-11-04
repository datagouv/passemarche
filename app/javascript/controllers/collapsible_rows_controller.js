import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 10 },
    showMoreLabel: String,
    showLessLabel: String,
    colspan: { type: Number, default: 1 }
  }

  connect () {
    const rows = Array.from(this.element.querySelectorAll('tr'))
    if (rows.length <= this.thresholdValue) return

    this.hiddenRows = rows.slice(this.thresholdValue)
    this.hiddenRows.forEach(row => { row.hidden = true })

    this.button = document.createElement('tr')
    this.button.innerHTML = `
      <td colspan="${this.colspanValue}" class="collapsible-rows__toggle-cell">
        <button type="button" class="collapsible-list__toggle collapsible-list__toggle--inline"></button>
      </td>
    `
    this.expanded = false
    this.toggleButton = this.button.querySelector('button')
    this.toggleButton.addEventListener('click', () => this.toggle())
    this.element.appendChild(this.button)
    this._updateLabel()
  }

  toggle () {
    this.expanded = !this.expanded
    this.hiddenRows.forEach(row => { row.hidden = !this.expanded })
    this._updateLabel()
  }

  _updateLabel () {
    const icon = document.createElement('span')
    icon.setAttribute('aria-hidden', 'true')
    icon.className = this.expanded ? 'fr-icon-arrow-up-s-line fr-mr-1w' : 'fr-icon-arrow-down-s-line fr-mr-1w'
    const text = document.createElement('span')
    text.textContent = this.expanded ? this.showLessLabelValue : this.showMoreLabelValue
    this.toggleButton.setAttribute('aria-expanded', String(this.expanded))
    this.toggleButton.replaceChildren(icon, text)
  }
}

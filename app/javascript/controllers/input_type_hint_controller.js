import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['select', 'hint']
  static values = { descriptions: Object }

  changed () {
    const selected = this.selectTarget.value
    this.hintTarget.textContent = this.descriptionsValue[selected] || ''
  }
}

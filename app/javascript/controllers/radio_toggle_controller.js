import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['field']
  static values = { show: { type: String, default: 'true' } }

  connect () {
    const checkedRadio = this.element.querySelector("input[type='radio']:checked")
    if (checkedRadio) {
      this.fieldTarget.hidden = checkedRadio.value !== this.showValue
    }
  }

  toggle (event) {
    this.fieldTarget.hidden = event.target.value !== this.showValue
  }
}

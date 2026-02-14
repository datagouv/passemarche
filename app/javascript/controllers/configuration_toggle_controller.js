import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['apiFields', 'radio']

  toggle () {
    const manualRadio = document.getElementById('config_manual')
    const isManual = manualRadio && manualRadio.checked

    this.apiFieldsTarget.style.display = isManual ? 'none' : ''
  }
}

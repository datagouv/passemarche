import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['apiFields', 'apiSelect', 'apiKeySelect']
  static values = { apiKeys: Object, currentApiKey: String }

  toggle () {
    const isManual = document.getElementById('config_manual').checked
    this.apiFieldsTarget.style.display = isManual ? 'none' : ''

    if (isManual) {
      if (this.hasApiSelectTarget) this.apiSelectTarget.value = ''
      if (this.hasApiKeySelectTarget) this.apiKeySelectTarget.value = ''
    }
  }

  apiChanged () {
    if (!this.hasApiKeySelectTarget) return

    const apiName = this.apiSelectTarget.value
    const keys = this.apiKeysValue[apiName] || []

    this.apiKeySelectTarget.innerHTML = ''

    if (keys.length === 0) {
      this.apiKeySelectTarget.add(new Option('—', ''))
      return
    }

    keys.forEach(key => {
      const option = new Option(key, key)
      if (key === this.currentApiKeyValue) option.selected = true
      this.apiKeySelectTarget.add(option)
    })

    this.currentApiKeyValue = ''
  }
}

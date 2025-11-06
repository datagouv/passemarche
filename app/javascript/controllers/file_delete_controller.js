import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    signedId: String,
    url: String,
    filename: String,
    confirmMessage: String,
    errorMessage: String,
    networkErrorMessage: String
  }

  delete(event) {
    event.preventDefault()

    if (!confirm(this.confirmMessageValue)) {
      return
    }

    this.performDelete()
  }

  async performDelete() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.urlValue, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.removeFileFromDOM()
      } else {
        this.showError(data.message || this.errorMessageValue)
      }
    } catch (error) {
      this.showError(this.networkErrorMessageValue)
      console.error('Delete error:', error)
    }
  }

  removeFileFromDOM() {
    const fileItem = this.element.closest('.file-item')
    if (fileItem) {
      const signedId = fileItem.dataset.signedId

      if (signedId) {
        const hiddenFields = document.querySelectorAll(`input[type="hidden"][data-signed-id="${signedId}"]`)
        hiddenFields.forEach(field => field.remove())
      }

      fileItem.remove()
    }
  }

  showError(message) {
    alert(message)
  }
}

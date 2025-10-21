import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    signedId: String,
    url: String,
    filename: String
  }

  delete(event) {
    event.preventDefault()

    const confirmMessage = `Êtes-vous sûr de vouloir supprimer le fichier "${this.filenameValue}" ?`

    if (!confirm(confirmMessage)) {
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
        this.showError(data.message || 'Erreur lors de la suppression')
      }
    } catch (error) {
      this.showError('Erreur réseau lors de la suppression')
      console.error('Delete error:', error)
    }
  }

  removeFileFromDOM() {
    const fileItem = this.element.closest('.file-item')
    if (fileItem) {
      fileItem.remove()
    }
  }

  showError(message) {
    alert(message)
  }
}

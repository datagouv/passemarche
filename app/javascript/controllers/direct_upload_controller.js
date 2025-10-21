import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["progress", "progressBar", "filesList"]
  static values = {
    marketApplicationIdentifier: String,
    deletable: Boolean
  }

  connect() {
    this.addEventListeners()
    this.attachFileInputListeners()
  }

  disconnect() {
    this.removeEventListeners()
  }

  attachFileInputListeners() {
    const fileInputs = this.element.querySelectorAll('input[type="file"][data-direct-upload-url]')
    fileInputs.forEach(input => {
      input.addEventListener('change', this.handleFileSelection.bind(this))
    })
  }

  handleFileSelection(event) {
    const input = event.target
    const files = Array.from(input.files)
    const url = input.dataset.directUploadUrl

    if (!url || files.length === 0) return

    files.forEach(file => this.uploadFile(file, input, url))
  }

  uploadFile(file, input, url) {
    const upload = new DirectUpload(file, url, this)

    upload.create((error, blob) => {
      if (error) {
        console.error('Upload failed:', error)
        this.showUploadErrorAlert(error)
        this.toggleProgressBar(false)
      } else {
        this.attachBlobToForm(input, blob)
        this.addFileToList(file.name, blob.signed_id)
        this.clearFileInput(input)
        this.hideProgressBarAfterDelay()
      }
    })
  }

  attachBlobToForm(input, blob) {
    const hiddenField = document.createElement('input')
    hiddenField.type = 'hidden'
    hiddenField.name = input.name
    hiddenField.value = blob.signed_id
    input.form.appendChild(hiddenField)
  }

  clearFileInput(input) {
    // Clear the file input to prevent duplicate uploads on form submit
    input.value = ''
  }

  addFileToList(filename, signedId) {
    if (!this.hasFilesListTarget) return

    // Remove "no files" message if present
    const emptyMessage = this.filesListTarget.querySelector('span')
    if (emptyMessage && emptyMessage.textContent.includes('Aucun fichier')) {
      emptyMessage.remove()
    }

    // Ensure the container has the right structure
    let documentsList = this.filesListTarget.querySelector('.fr-mt-2w')
    if (!documentsList) {
      documentsList = document.createElement('div')
      documentsList.className = 'fr-mt-2w fr-text--sm fr-mb-0'

      const header = document.createElement('strong')
      header.textContent = 'Documents actuels :'
      documentsList.appendChild(header)

      this.filesListTarget.appendChild(documentsList)
    }

    // Create file item
    const fileItem = document.createElement('div')
    fileItem.className = 'file-item'
    fileItem.dataset.signedId = signedId

    const fileLink = document.createElement('span')
    fileLink.className = 'file-link'
    fileLink.textContent = filename
    fileItem.appendChild(fileLink)

    if (this.deletableValue && this.marketApplicationIdentifierValue) {
      const deleteWrapper = document.createElement('span')
      deleteWrapper.className = 'file-delete-wrapper'

      const deleteButton = document.createElement('button')
      deleteButton.type = 'button'
      deleteButton.className = 'fr-btn fr-btn--tertiary-no-outline fr-btn--sm fr-icon-delete-line'
      deleteButton.textContent = 'Supprimer'
      deleteButton.title = `Supprimer ${filename}`
      deleteButton.dataset.controller = 'file-delete'
      deleteButton.dataset.fileDeleteSignedIdValue = signedId
      deleteButton.dataset.fileDeleteUrlValue = `/candidate/market_applications/${this.marketApplicationIdentifierValue}/attachments/${signedId}`
      deleteButton.dataset.fileDeleteFilenameValue = filename
      deleteButton.dataset.action = 'click->file-delete#delete'

      deleteWrapper.appendChild(deleteButton)
      fileItem.appendChild(deleteWrapper)
    }

    documentsList.appendChild(fileItem)
  }

  // DirectUpload callbacks (called by DirectUpload)
  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress", event => {
      const progress = (event.loaded / event.total) * 100
      this.updateProgressBar(progress)
    })
    this.toggleProgressBar(true)
  }

  uploadInitialize(event) {
    if (!this.isEventFromThisController(event)) return

    this.resetProgressBar()
  }

  uploadStart(event) {
    if (!this.isEventFromThisController(event)) return

    this.toggleProgressBar(true)
  }

  uploadProgress(event) {
    if (!this.isEventFromThisController(event)) return

    const { progress } = event.detail
    this.updateProgressBar(progress)
  }

  uploadError(event) {
    if (!this.isEventFromThisController(event)) return

    event.preventDefault()
    const { error } = event.detail

    this.toggleProgressBar(false)
    this.showUploadErrorAlert(error)
  }

  uploadEnd(event) {
    if (!this.isEventFromThisController(event)) return

    this.hideProgressBarAfterDelay()
  }

  isEventFromThisController(event) {
    return this.element.contains(event.target)
  }

  addEventListeners() {
    this.boundHandlers = {
      "direct-upload:initialize": this.uploadInitialize.bind(this),
      "direct-upload:start": this.uploadStart.bind(this),
      "direct-upload:progress": this.uploadProgress.bind(this),
      "direct-upload:error": this.uploadError.bind(this),
      "direct-upload:end": this.uploadEnd.bind(this)
    }

    Object.entries(this.boundHandlers).forEach(([eventName, handler]) => {
      this.element.addEventListener(eventName, handler)
    })
  }

  removeEventListeners() {
    Object.entries(this.boundHandlers).forEach(([eventName, handler]) => {
      this.element.removeEventListener(eventName, handler)
    })
  }

  hasProgressComponents() {
    return this.hasProgressTarget && this.hasProgressBarTarget
  }

  resetProgressBar() {
    if (this.hasProgressComponents()) {
      this.progressBarTarget.style.width = "0%"
    }
  }

  toggleProgressBar(visible) {
    if (this.hasProgressTarget) {
      this.progressTarget.classList.toggle("hidden", !visible)
    }
  }

  updateProgressBar(progress) {
    if (this.hasProgressComponents()) {
      this.progressBarTarget.style.width = `${progress}%`
    }
  }

  hideProgressBarAfterDelay(delay = 500) {
    if (this.hasProgressTarget) {
      setTimeout(() => this.toggleProgressBar(false), delay)
    }
  }

  showUploadErrorAlert(error) {
    alert(`Erreur lors du téléchargement: ${error}`)
  }
}

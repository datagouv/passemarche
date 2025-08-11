import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "button"]

  async copy() {
    try {
      // Get the text to copy
      const textToCopy = this.textTarget.textContent.trim()
      
      // Use modern Clipboard API if available
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(textToCopy)
      } else {
        // Fallback for older browsers
        this.fallbackCopy(textToCopy)
      }
      
      // Visual feedback
      this.showSuccess()
      
    } catch (error) {
      console.error('Failed to copy text:', error)
      this.showError()
    }
  }

  fallbackCopy(text) {
    // Create temporary textarea for fallback copy
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    
    textarea.select()
    textarea.setSelectionRange(0, 99999) // For mobile devices
    
    document.execCommand('copy')
    document.body.removeChild(textarea)
  }

  showSuccess() {
    const originalText = this.buttonTarget.textContent
    const originalClasses = this.buttonTarget.className
    
    // Change to success state
    this.buttonTarget.textContent = "Copié !"
    this.buttonTarget.className = originalClasses.replace('fr-icon-clipboard-line', 'fr-icon-check-line')
    
    // Reset after 2 seconds
    setTimeout(() => {
      this.buttonTarget.textContent = originalText
      this.buttonTarget.className = originalClasses
    }, 2000)
  }

  showError() {
    const originalText = this.buttonTarget.textContent
    
    // Change to error state
    this.buttonTarget.textContent = "Erreur"
    
    // Reset after 2 seconds
    setTimeout(() => {
      this.buttonTarget.textContent = originalText
    }, 2000)
  }
}
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    this.element.showModal()
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
  }

  disconnect () {
    document.removeEventListener('keydown', this.boundKeydown)
  }

  close () {
    this.element.close()
    const frame = this.element.closest('turbo-frame')
    if (frame) frame.innerHTML = ''
  }

  clickBackdrop (event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  keydown (event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}

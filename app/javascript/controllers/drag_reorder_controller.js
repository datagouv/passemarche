import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static values = { url: String }

  connect () {
    this.sortable = Sortable.create(this.element, {
      handle: '[data-drag-handle]',
      animation: 150,
      dataIdAttr: 'data-item-id',
      onEnd: this.reorder.bind(this)
    })
  }

  disconnect () {
    if (this.sortable) this.sortable.destroy()
  }

  async reorder () {
    const orderedIds = this.sortable.toArray()
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ ordered_ids: orderedIds })
    })

    if (!response.ok) window.location.reload()
  }
}

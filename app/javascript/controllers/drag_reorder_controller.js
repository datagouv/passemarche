import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static values = { url: String }

  connect () {
    this.sortable = Sortable.create(this.element, {
      handle: '[data-drag-handle]',
      animation: 150,
      onEnd: this.reorder.bind(this)
    })
  }

  disconnect () {
    if (this.sortable) this.sortable.destroy()
  }

  async reorder () {
    const rows = this.element.querySelectorAll('tr[data-item-id]')
    const orderedIds = Array.from(rows).map((row) => row.dataset.itemId)
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ ordered_ids: orderedIds })
    })
  }
}

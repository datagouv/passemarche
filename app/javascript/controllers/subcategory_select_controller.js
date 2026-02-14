import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categorySelect", "subcategorySelect"]
  static values = { subcategories: Array }

  connect() {
    this.filterSubcategories()
  }

  filterSubcategories() {
    const selectedCategoryKey = this.categorySelectTarget.value
    const subcategorySelect = this.subcategorySelectTarget

    const options = subcategorySelect.querySelectorAll("option[data-category-key]")
    options.forEach(option => {
      option.hidden = selectedCategoryKey && option.dataset.categoryKey !== selectedCategoryKey
    })

    if (subcategorySelect.selectedOptions[0]?.hidden) {
      subcategorySelect.value = ""
    }
  }
}

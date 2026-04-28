import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'buyerCategory',
    'buyerSubcategory',
    'candidateCategory',
    'candidateSubcategory',
    'subcategoryId'
  ]

  static values = {
    subcategories: Array
  }

  connect () {
    this.syncFromCurrentSubcategory()
    this.syncFromCurrentCategory()
  }

  categoryChanged () {
    const categoryId = parseInt(this.buyerCategoryTarget.value)

    this.filterSubcategories(categoryId)
    this.syncCandidateCategory()
    this.syncCandidateSubcategory()
    this.updateHiddenField()
  }

  subcategoryChanged () {
    this.syncCandidateSubcategory()
    this.updateHiddenField()
  }

  // private

  syncFromCurrentCategory () {
    if (this.subcategoryIdTarget.value) return

    const categoryId = parseInt(this.buyerCategoryTarget.value)
    if (!categoryId) return

    this.filterSubcategories(categoryId)
    this.syncCandidateCategory()
  }

  syncFromCurrentSubcategory () {
    const currentSubcategoryId = this.subcategoryIdTarget.value
    if (!currentSubcategoryId) return

    const numericId = parseInt(currentSubcategoryId)
    const subcategory = this.subcategoriesValue.find(s => s.id === numericId)
    if (!subcategory) return

    this.buyerCategoryTarget.value = String(subcategory.categoryId)
    this.filterSubcategories(subcategory.categoryId)
    this.buyerSubcategoryTarget.value = currentSubcategoryId
    this.syncCandidateCategory()
    this.syncCandidateSubcategory()
  }

  filterSubcategories (categoryId) {
    const filtered = this.subcategoriesValue.filter(s => s.categoryId === categoryId)

    this.clearSelect(this.buyerSubcategoryTarget)
    this.clearSelect(this.candidateSubcategoryTarget)

    filtered.forEach(sub => {
      const id = String(sub.id)
      this.buyerSubcategoryTarget.add(new Option(sub.buyerLabel, id))
      this.candidateSubcategoryTarget.add(new Option(sub.candidateLabel, id))
    })
  }

  syncCandidateCategory () {
    const selectedOption = this.buyerCategoryTarget.options[this.buyerCategoryTarget.selectedIndex]
    if (!selectedOption) return

    const categoryId = selectedOption.value

    for (const option of this.candidateCategoryTarget.options) {
      if (option.value === categoryId) {
        option.selected = true
        break
      }
    }
  }

  syncCandidateSubcategory () {
    const selectedValue = this.buyerSubcategoryTarget.value
    this.candidateSubcategoryTarget.value = selectedValue
  }

  updateHiddenField () {
    this.subcategoryIdTarget.value = this.buyerSubcategoryTarget.value
  }

  clearSelect (selectElement) {
    while (selectElement.options.length > 0) {
      selectElement.remove(0)
    }
  }
}

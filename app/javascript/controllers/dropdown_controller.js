import { Controller } from "@hotwired/stimulus"

/**
 * Dropdown Controller
 *
 * A Stimulus controller for DSFR-style dropdown buttons.
 * Handles the open/close behavior of a dropdown menu.
 *
 * Usage:
 *   <div class="fr-dropdown" data-controller="dropdown">
 *     <button class="fr-btn fr-btn--icon-right fr-icon-arrow-down-s-line"
 *             data-dropdown-target="button"
 *             data-action="click->dropdown#toggle"
 *             aria-expanded="false"
 *             aria-controls="dropdown-menu-1">
 *       Label
 *     </button>
 *     <div class="fr-collapse fr-menu"
 *          data-dropdown-target="content"
 *          id="dropdown-menu-1">
 *       <ul class="fr-menu__list">
 *         <li><a class="fr-nav__link" href="#">Option 1</a></li>
 *       </ul>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["button", "content"]

  connect() {
    this.syncState()
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    const isExpanded = this.buttonTarget.getAttribute("aria-expanded") === "true"

    if (isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.contentTarget.classList.add("fr-collapse--expanded")
    document.addEventListener("click", this.boundClickOutside)
  }

  collapse() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.contentTarget.classList.remove("fr-collapse--expanded")
    document.removeEventListener("click", this.boundClickOutside)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.collapse()
    }
  }

  // Sync visual state with aria-expanded attribute on connect
  syncState() {
    const isExpanded = this.buttonTarget.getAttribute("aria-expanded") === "true"

    if (isExpanded) {
      this.contentTarget.classList.add("fr-collapse--expanded")
    } else {
      this.contentTarget.classList.remove("fr-collapse--expanded")
    }
  }
}

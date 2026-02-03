import { Controller } from "@hotwired/stimulus"

/**
 * Accordion Controller
 *
 * A Stimulus controller for DSFR accordions that works seamlessly with Turbo.
 * Uses DSFR's CSS classes for styling but handles JavaScript behavior ourselves.
 *
 * Usage:
 *   <section class="fr-accordion" data-controller="accordion">
 *     <h3 class="fr-accordion__title">
 *       <button class="fr-accordion__btn"
 *               data-accordion-target="button"
 *               data-action="click->accordion#toggle"
 *               aria-expanded="false"
 *               aria-controls="accordion-1">
 *         Title
 *       </button>
 *     </h3>
 *     <div class="fr-collapse"
 *          data-accordion-target="content"
 *          id="accordion-1">
 *       Content here
 *     </div>
 *   </section>
 */
export default class extends Controller {
  static targets = ["button", "content"]

  connect() {
    this.syncState()
  }

  toggle() {
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
  }

  collapse() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.contentTarget.classList.remove("fr-collapse--expanded")
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

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.updateCurrentPage()

    document.addEventListener("turbo:load", () => this.updateCurrentPage())
    window.addEventListener("hashchange", () => this.updateCurrentPage())
  }

  disconnect() {
    document.removeEventListener("turbo:load", () => this.updateCurrentPage())
    window.removeEventListener("hashchange", () => this.updateCurrentPage())
  }

  click(event) {
    const targetHref = event.currentTarget.getAttribute("href")
    this.setCurrentLink(event.currentTarget)
  }

  setCurrentLink(activeLink) {
    this.linkTargets.forEach(link => {
      if (link === activeLink) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }

  updateCurrentPage() {
    const currentHash = window.location.hash

    this.linkTargets.forEach(link => {
      const linkHref = link.getAttribute("href")

      if (linkHref === currentHash) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }
}

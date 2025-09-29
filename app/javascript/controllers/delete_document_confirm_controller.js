import { Controller } from "@hotwired/stimulus"

// Stimulus controller for custom confirmation and delete for document buttons
export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (e) => {
      const btn = e.target.closest(".delete-document-btn");
      if (!btn) return;
      const message = btn.getAttribute("data-turbo-confirm") || "Êtes-vous sûr de vouloir supprimer ce document ?";
      if (!window.confirm(message)) {
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      // Get document id and market application id
      const documentId = btn.getAttribute("data-document-id");
      const marketApplicationId = this.element.getAttribute("data-market-application-id");
      if (!documentId || !marketApplicationId) return;
      const url = `/candidate/market_applications/${marketApplicationId}/documents/${documentId}`;
      fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          "Accept": "text/vnd.turbo-stream.html"
        }
      }).then(response => {
        if (response.ok) {
          // Remove the turbo-frame for this document
          const frame = btn.closest("turbo-frame");
          if (frame) { frame.remove(); }
        }
      });
      e.preventDefault();
      e.stopPropagation();
    });
  }
}

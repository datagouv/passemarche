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
      // Safely get CSRF token meta tag
      const csrfMeta = document.querySelector('meta[name="csrf-token"]');
      if (!csrfMeta) {
        console.error("CSRF meta tag not found. Aborting document delete request.");
        return;
      }
      const url = `/candidate/market_applications/${marketApplicationId}/documents/${documentId}`;
      fetch(url, {
        method: "DELETE",
        headers: {
          // Safely get CSRF token
          "X-CSRF-Token": (() => {
            const meta = document.querySelector('meta[name="csrf-token"]');
            return meta ? meta.getAttribute('content') : "";
          })(),
          "Accept": "text/vnd.turbo-stream.html"
        }
      }).then(response => {
        if (response.ok) {
          // Remove the turbo-frame for this document
          const frame = btn.closest("turbo-frame");
          if (frame) { frame.remove(); }
          } else {
            window.alert("La suppression du document a échoué. Veuillez réessayer.");
          }
        }).catch(error => {
          window.alert("Une erreur réseau est survenue lors de la suppression du document.");
        });
      e.preventDefault();
      e.stopPropagation();
    });
  }
}

// Enhanced JavaScript for improved user experience
document.addEventListener('DOMContentLoaded', function() {

  // Initialize SIRET input formatting
  initializeSiretFormatting();

  // Initialize form validation
  initializeFormValidation();

  // Smooth scroll to anchors
  initializeSmoothScroll();

  // Auto-close alerts after delay
  autoCloseAlerts();
});

/**
 * Format SIRET input - allow only 14 digits
 */
function initializeSiretFormatting() {
  const siretInputs = document.querySelectorAll('input[name="siret"]');

  siretInputs.forEach(input => {
    input.addEventListener('input', function(e) {
      // Remove non-digit characters
      let value = e.target.value.replace(/\D/g, '');

      // Limit to 14 digits
      if (value.length > 14) {
        value = value.slice(0, 14);
      }

      e.target.value = value;

      // Visual feedback for valid SIRET
      if (value.length === 14) {
        e.target.classList.add('fr-input--valid');
        e.target.classList.remove('fr-input--error');
      } else if (value.length > 0) {
        e.target.classList.remove('fr-input--valid');
      }
    });
  });
}

/**
 * Initialize form validation
 */
function initializeFormValidation() {
  const forms = document.querySelectorAll('form[data-validate="true"]');

  forms.forEach(form => {
    form.addEventListener('submit', function(e) {
      const requiredFields = form.querySelectorAll('[required]');
      let isValid = true;

      requiredFields.forEach(field => {
        if (!field.value.trim()) {
          isValid = false;
          field.classList.add('fr-input--error');
        } else {
          field.classList.remove('fr-input--error');
        }
      });

      if (!isValid) {
        e.preventDefault();
        alert('Veuillez remplir tous les champs obligatoires.');
      }
    });
  });
}

/**
 * Smooth scroll to anchor links
 */
function initializeSmoothScroll() {
  const anchorLinks = document.querySelectorAll('a[href^="#"]');

  anchorLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;

      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        e.preventDefault();
        targetElement.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
  });
}

/**
 * Auto-close success alerts after 10 seconds
 */
function autoCloseAlerts() {
  const successAlerts = document.querySelectorAll('.fr-alert--success');

  successAlerts.forEach(alert => {
    setTimeout(() => {
      alert.style.transition = 'opacity 0.5s ease';
      alert.style.opacity = '0';
      setTimeout(() => {
        alert.style.display = 'none';
      }, 500);
    }, 10000);
  });
}
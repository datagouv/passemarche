// Simple JavaScript for enhanced user experience
document.addEventListener('DOMContentLoaded', function() {
  // Auto-refresh token expiry countdown
  const statusValid = document.querySelector('.status-valid');
  if (statusValid && statusValid.textContent.includes('expire dans')) {
    setInterval(() => {
      const match = statusValid.textContent.match(/expire dans (\d+)s/);
      if (match) {
        const seconds = parseInt(match[1]) - 1;
        if (seconds > 0) {
          statusValid.textContent = statusValid.textContent.replace(/expire dans \d+s/, `expire dans ${seconds}s`);
        } else {
          statusValid.textContent = '❌ Expiré';
          statusValid.className = 'status-expired';
        }
      }
    }, 1000);
  }
});
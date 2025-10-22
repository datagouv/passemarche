// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import * as ActiveStorage from "@rails/activestorage"

// Start ActiveStorage when DOM is ready (for normal page loads)
document.addEventListener('DOMContentLoaded', () => {
  ActiveStorage.start()
})

// Start ActiveStorage on Turbo navigations
document.addEventListener('turbo:load', () => {
  ActiveStorage.start()
})

// Start ActiveStorage on Turbo frame loads
document.addEventListener('turbo:frame-load', () => {
  ActiveStorage.start()
})

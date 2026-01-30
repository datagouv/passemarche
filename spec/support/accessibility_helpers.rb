# frozen_string_literal: true

require 'axe-rspec'
require 'axe-capybara'
require 'selenium-webdriver'

# Register a headless Chromium driver for accessibility tests
Capybara.register_driver :headless_chromium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  chrome_path = ENV.fetch('CHROME_BIN', nil) ||
                (File.exist?('/usr/bin/chromium-browser') ? '/usr/bin/chromium-browser' : nil) ||
                (File.exist?('/usr/bin/google-chrome') ? '/usr/bin/google-chrome' : nil)

  options.binary = chrome_path if chrome_path
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

module AccessibilityHelpers
  # DSFR-specific selectors that may have known accessibility issues
  # that are being addressed at the design system level
  DSFR_EXCLUSIONS = [
    # Modal dialogs with specific DSFR implementation
    '.fr-modal__overlay'
  ].freeze

  # Check page accessibility with optional exclusions
  def check_accessibility(exclusions: DSFR_EXCLUSIONS)
    if exclusions.any?
      expect(page).to be_axe_clean.excluding(*exclusions)
    else
      expect(page).to be_axe_clean
    end
  end

  # Check accessibility with WCAG 2.1 AA standard
  def check_accessibility_wcag21aa(exclusions: DSFR_EXCLUSIONS)
    if exclusions.any?
      expect(page).to be_axe_clean
        .according_to(:wcag21aa)
        .excluding(*exclusions)
    else
      expect(page).to be_axe_clean.according_to(:wcag21aa)
    end
  end
end

RSpec.configure do |config|
  config.include AccessibilityHelpers, type: :accessibility
  config.include AccessibilityHelpers, type: :system
  config.include AccessibilityHelpers, type: :feature
end

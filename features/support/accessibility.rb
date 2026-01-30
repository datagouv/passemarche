# frozen_string_literal: true

require 'axe-capybara'
require 'axe-cucumber-steps'

# DSFR-specific selectors that may have known accessibility issues
DSFR_EXCLUSIONS = [
  '.fr-modal__overlay'
].freeze

# Check page accessibility with optional exclusions
def check_page_accessibility(exclusions: DSFR_EXCLUSIONS)
  if exclusions.any?
    expect(page).to be_axe_clean.excluding(*exclusions)
  else
    expect(page).to be_axe_clean
  end
end

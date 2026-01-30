# frozen_string_literal: true

require 'axe-capybara'

# DSFR-specific selectors that may have known accessibility issues
DSFR_EXCLUSIONS = [
  '.fr-modal__overlay'
].freeze

# Check page accessibility with optional exclusions
def check_page_accessibility(exclusions: DSFR_EXCLUSIONS)
  axe = Axe::Capybara.new(page)
  exclusions.each { |selector| axe.exclude(selector) }
  results = axe.call

  violations = results.results.violations
  raise format_violations(violations) if violations.any?
end

def format_violations(violations)
  messages = violations.map { |v| format_violation(v) }
  "Found #{violations.size} accessibility violation(s):\n#{messages.join("\n\n")}"
end

def format_violation(violation)
  "#{violation.id}: #{violation.description} (#{violation.impact})\n  #{violation.nodes.map(&:html).join("\n  ")}"
end

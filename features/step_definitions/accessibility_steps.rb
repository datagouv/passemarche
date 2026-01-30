# frozen_string_literal: true

Then('the page should be accessible') do
  check_page_accessibility
end

Then('the page should be accessible excluding {string}') do |selector|
  exclusions = selector.split(',').map(&:strip)
  check_page_accessibility(exclusions:)
end

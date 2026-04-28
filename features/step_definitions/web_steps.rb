# frozen_string_literal: true

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

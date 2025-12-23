# frozen_string_literal: true

Given('I am on the home page') do
  visit root_path
end

Given('I am on the candidate home page') do
  visit candidate_home_path
end

Given('I am on the buyer home page') do
  visit buyer_home_path
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should see the same content as the buyer homepage') do
  home_main_content = page.find('.fr-callout').text
  visit buyer_home_path
  buyer_main_content = page.find('.fr-callout').text
  expect(home_main_content).to eq(buyer_main_content)
end

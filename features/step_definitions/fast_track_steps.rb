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

Then('I should see a link {string} in the header') do |link_text|
  within('header.fr-header') do
    expect(page).to have_link(link_text)
  end
end

Then('the candidate navigation link should be active') do
  within('header.fr-header') do
    expect(page).to have_css('a.fr-link--active', text: I18n.t('header.navigation.candidate'))
  end
end

Then('the candidate navigation link should not be active') do
  within('header.fr-header') do
    expect(page).to have_no_css('a.fr-link--active', text: I18n.t('header.navigation.candidate'))
  end
end

Then('the buyer navigation link should be active') do
  within('header.fr-header') do
    expect(page).to have_css('a.fr-link--active', text: I18n.t('header.navigation.buyer'))
  end
end

Then('the buyer navigation link should not be active') do
  within('header.fr-header') do
    expect(page).to have_no_css('a.fr-link--active', text: I18n.t('header.navigation.buyer'))
  end
end

# frozen_string_literal: true

When('I set lot {string} to {string}') do |lot_name, mode|
  lot = Lot.find_by!(name: lot_name)
  find("label[for='lot_mode_#{lot.id}_#{mode}']").click
end

When('I visit the read-only candidacy mode step of the solo application') do
  solo_application = @market_application.solo_counterpart || @market_application
  visit grouping_wizard_step_candidate_market_application_path(solo_application.identifier, :application_mode, readonly: true)
end

When('I apply {string} to the typology {string}') do |label, market_type_code|
  section = find('.lot-selection-mode-group', text: I18n.t("market_types.#{market_type_code}"))
  within(section) { find('option', text: label).select_option }
end

Then('each lot should offer the options {string}, {string} and {string}') do |*labels|
  labels.each { |label| expect(page).to have_css('.lot-mode-choice__label', text: label) }
end

Then('each lot should offer the options {string} and {string}') do |first_label, second_label|
  expect(page).to have_css('.lot-mode-choice__label', text: first_label)
  expect(page).to have_css('.lot-mode-choice__label', text: second_label)
end

Then('the lot option {string} should not be visible') do |label|
  expect(page).not_to have_css('.lot-mode-choice__label', text: label)
end

Then('every lot should be set to {string}') do |label|
  mode = mode_key_for_label(label)
  page.all("input[name^='lot_modes'][value='#{mode}']").each do |radio|
    expect(radio).to be_checked
  end
end

Then('lot {string} should be set to {string}') do |lot_name, label|
  lot = Lot.find_by!(name: lot_name)
  mode = mode_key_for_label(label)
  expect(page).to have_css("#lot_mode_#{lot.id}_#{mode}:checked", visible: :all)
end

Then('every lot of the typology {string} should be set to {string}') do |market_type_code, label|
  mode = mode_key_for_label(label)
  market_type = MarketType.find_by!(code: market_type_code)
  Lot.where(market_type:).or(Lot.where(platform_market_type: market_type)).each do |lot|
    expect(page).to have_css("#lot_mode_#{lot.id}_#{mode}:checked", visible: :all)
  end
end

Then('I should see a section for the lot typology {string}') do |market_type_code|
  expect(page).to have_css('.lot-selection-mode-group', text: I18n.t("market_types.#{market_type_code}"))
end

def mode_key_for_label(label)
  %w[solo groupement none].find { |mode| I18n.t("candidate.lot_selection_modes.#{mode}") == label }
end

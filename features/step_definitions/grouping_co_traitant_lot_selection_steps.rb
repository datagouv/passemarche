# frozen_string_literal: true

Given('the public market has the lots {string}, {string} and {string}') do |name1, name2, name3|
  [name1, name2, name3].each { |name| create(:lot, public_market: @public_market, name:) }
end

Given('I assign {string} and {string} to the groupement') do |name1, name2|
  groupement_lot_names = [name1, name2]
  @public_market.lots.each do |lot|
    mode = groupement_lot_names.include?(lot.name) ? 'groupement' : 'none'
    find("label[for='lot_mode_#{lot.id}_#{mode}']").click
  end
  click_button I18n.t('candidate.lot_selection_modes.continue')
end

When('I check the lot {string}') do |lot_name|
  lot = Lot.find_by!(public_market: @public_market, name: lot_name)
  find("label[for='lot_#{lot.id}']").click
end

When('I submit the lot selection') do
  click_button I18n.t('candidate.lot_selection.next')
end

Then('the lot selection submit button should be disabled') do
  expect(page).to have_button(I18n.t('candidate.lot_selection.next'), disabled: true)
end

Then('the lot selection submit button should be enabled') do
  expect(page).to have_button(I18n.t('candidate.lot_selection.next'), disabled: false)
end

Then('the side panel should show the public market name') do
  expect(page).to have_content(@public_market.name)
end

Then('the selected lots panel should be empty') do
  expect(page).to have_css("[data-lot-selection-target='noLotsText']", text: I18n.t('candidate.lot_selection.no_lot_selected'))
end

Then('the selected lots panel should list {string}') do |lot_name|
  expect(page).to have_css("[data-lot-selection-target='selectedLotsTags']", text: lot_name)
end

Then('the selected lots panel should not list {string}') do |lot_name|
  expect(page).to have_no_css("[data-lot-selection-target='selectedLotsTags']", text: lot_name)
end

When('I visit the grouping dashboard as the co-traitant with SIRET {string}') do |siret|
  member = GroupingMember.find_by!(siret:)
  identifier = member.market_application.identifier
  visit grouping_dashboard_candidate_market_application_path(identifier)
end

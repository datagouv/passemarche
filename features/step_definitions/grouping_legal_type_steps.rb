# frozen_string_literal: true

When('I choose the grouping legal type {string}') do |legal_type|
  find("label[for='legal_type_#{legal_type}']").click
  click_button I18n.t('candidate.grouping_legal_types.continue')
end

When('I visit the grouping legal type step directly') do
  visit grouping_wizard_step_candidate_market_application_path(@market_application.identifier, :grouping_legal_type)
end

Then('the grouping legal type should be {string}') do |legal_type|
  grouping = Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: @market_application.id })
  expect(grouping.legal_type).to eq(legal_type)
end

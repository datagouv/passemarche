# frozen_string_literal: true

Given('the groupement feature flag is enabled') do
  FeatureFlags::Groupement.define_singleton_method(:enabled?) { true }
end

Given('the groupement feature flag is disabled') do
  FeatureFlags::Groupement.define_singleton_method(:enabled?) { false }
end

Given('the candidate application already has the mode {string}') do |mode|
  @market_application.update!(application_mode: mode)
end

Given('the SIRET is already mandataire of a groupement on this market') do
  mandataire_application = create(:market_application, public_market: @public_market,
    siret: @market_application.siret, application_mode: :groupement)
  create(:grouping, public_market: @public_market, mandataire_market_application: mandataire_application)
end

When('I choose the candidacy mode {string}') do |mode|
  find("label[for='application_mode_#{mode}']").click
  click_button I18n.t('candidate.application_modes.continue')
end

Then('I should be on the company identification step') do
  expect(page).to have_current_path(
    company_identification_candidate_market_application_path(@market_application.identifier),
    ignore_query: true
  )
end

Then('I should be on the grouping legal type step') do
  expect(page).to have_current_path(
    grouping_legal_type_candidate_market_application_path(@market_application.identifier),
    ignore_query: true
  )
end

Then('I should be on the candidacy mode choice step') do
  expect(page).to have_current_path(
    application_mode_candidate_market_application_path(@market_application.identifier),
    ignore_query: true
  )
end

Then('I should land on the company identification step of the groupement application') do
  expect(page).to have_current_path(%r{/candidate/market_applications/.+/company_identification})

  landed_identifier = page.current_path[%r{/candidate/market_applications/([^/]+)/company_identification}, 1]
  expect(landed_identifier).not_to eq(@market_application.identifier)
end

Then('I should land on the grouping legal type step of the groupement application') do
  expect(page).to have_current_path(%r{/candidate/market_applications/.+/grouping_legal_type})

  landed_identifier = page.current_path[%r{/candidate/market_applications/([^/]+)/grouping_legal_type}, 1]
  expect(landed_identifier).not_to eq(@market_application.identifier)

  @groupement_market_application = MarketApplication.find_by!(identifier: landed_identifier)
end

Then('my application mode should be {string}') do |mode|
  expect(@market_application.reload.application_mode).to eq(mode)
end

Then('I should be the mandataire of a new groupement') do
  grouping = Grouping.joins(:mandataire_grouping_member)
    .find_by(mandataire_grouping_member: { market_application_id: @market_application.id })
  expect(grouping).to be_present
  expect(grouping.grouping_members.sole).to be_mandataire
end

Then('a second market application should exist with mode {string}') do |mode|
  groupement_application = MarketApplication
    .where(public_market: @market_application.public_market, siret: @market_application.siret)
    .where.not(id: @market_application.id)
    .sole

  expect(groupement_application.application_mode).to eq(mode)
end

Then('the candidacy mode {string} should be disabled') do |mode|
  expect(page).to have_field(I18n.t("candidate.application_modes.#{mode}.label"), disabled: true)
end

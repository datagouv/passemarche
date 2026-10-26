# frozen_string_literal: true

Given('I am not authenticated') do
  Capybara.reset_session!
end

When('I visit the dashboard') do
  visit candidate_dashboard_path
end

Then('I should see my application market name') do
  expect(page).to have_text(@market_application.public_market.name)
end

Then('I should not see the other application market name') do
  expect(page).not_to have_text(@other_market_application.public_market.name)
end

Given('my application has been submitted') do
  @market_application.update!(completed_at: Time.zone.now, sync_status: :sync_completed)
end

Given('another application exists for a different candidate') do
  other_public_market = create(:public_market, :completed, editor: @public_market.editor,
    name: 'Marché autre candidat')
  @other_market_application = create(:market_application, public_market: other_public_market, siret: '41816609600069')
end

Given('a second in-progress application exists for my account') do
  @market_application.reload
  other_public_market = create(:public_market, :completed, editor: @public_market.editor)
  @second_market_application = create(:market_application, public_market: other_public_market,
    siret: @market_application.siret,
    user: @market_application.user)
end

Then('I should see {string} for in-progress count') do |count|
  within('.fr-dashboard-tile--blue') do
    expect(page).to have_text(count)
  end
end

Then('I should see {string} for completed count') do |count|
  within('.fr-dashboard-tile--green') do
    expect(page).to have_text(count)
  end
end

Given('the public market has a buyer name {string}') do |buyer_name|
  @public_market.update!(buyer_name:)
end

Given('my application is a co-traitant of a grouping') do
  @market_application.reload.update!(application_mode: :groupement)
  mandataire_application = create(:market_application, public_market: @public_market, siret: '41816609600069',
    application_mode: :groupement)
  grouping = create(:grouping, public_market: @public_market, mandataire_market_application: mandataire_application)
  @grouping_member = create(:grouping_member, :co_traitant, grouping:, market_application: @market_application,
    siret: @market_application.siret)
end

Given('the grouping has been submitted') do
  @grouping_member.grouping.update!(submitted_at: Time.zone.now, submission_mode: :partial)
end

Given('I also apply as mandataire of a grouping on the same market') do
  @market_application.reload.update!(application_mode: :solo)
  groupement_application = create(:market_application, public_market: @public_market, siret: @market_application.siret,
    user: @market_application.user, application_mode: :groupement)
  create(:grouping, public_market: @public_market, mandataire_market_application: groupement_application)
end

Then('I should see a single card for my application market') do
  expect(page).to have_css('.fr-card h2', text: @public_market.name, count: 1)
end

Then('the market card should list {string} then {string}') do |first_kind, second_kind|
  kinds = all('.dashboard-application-row h3').map(&:text)
  expect(kinds).to eq([first_kind, second_kind])
end

Then('I should not see my application market name') do
  expect(page).not_to have_text(@market_application.public_market.name)
end

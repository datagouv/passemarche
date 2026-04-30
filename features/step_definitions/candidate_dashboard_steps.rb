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

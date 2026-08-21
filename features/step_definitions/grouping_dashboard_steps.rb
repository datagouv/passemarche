# frozen_string_literal: true

def mandataire_grouping
  Grouping.joins(:mandataire_grouping_member)
    .find_by(mandataire_grouping_member: { market_application_id: @market_application.id })
end

Then('I should be on the grouping dashboard') do
  expect(page).to have_current_path(
    grouping_dashboard_candidate_market_application_path(@market_application.identifier),
    ignore_query: true
  )
end

When('I visit the grouping dashboard') do
  visit grouping_dashboard_candidate_market_application_path(@market_application.identifier)
end

When('I visit the grouping dashboard directly') do
  visit grouping_dashboard_candidate_market_application_path(@market_application.identifier)
end

Then('the co-traitant {string} should have status {string}') do |siret, status|
  member = GroupingMember.find_by!(siret:)
  within("#grouping_member_row_#{member.id}") { expect(page).to have_content(/#{Regexp.escape(status)}/i) }
end

Then('the co-traitant {string} should have the action {string}') do |siret, action_label|
  member = GroupingMember.find_by!(siret:)
  within("#grouping_member_actions_#{member.id}") { expect(page).to have_content(action_label) }
end

VALID_TEST_SIRETS = %w[80245139601003 80245139601011 80245139601029].freeze

Given('every member of the grouping is completed') do
  grouping = mandataire_grouping
  grouping.mandataire_grouping_member.update!(status: :completed)
  grouping.grouping_members.co_traitant.each_with_index do |member, index|
    member_application = member.market_application ||
                         create(:market_application, public_market: @public_market, application_mode: :groupement,
                           siret: VALID_TEST_SIRETS[index])
    member.update!(status: :completed, market_application: member_application)
  end
end

Given('a co-traitant of the grouping is in progress') do
  grouping = mandataire_grouping
  member_application = create(:market_application, public_market: @public_market, application_mode: :groupement,
    siret: VALID_TEST_SIRETS[0])
  create(:grouping_member, :co_traitant, grouping:, status: :in_progress, market_application: member_application,
    siret: VALID_TEST_SIRETS[0])
end

Given('the candidate application also has a solo counterpart on the same market') do
  solo_application = create(:market_application, public_market: @public_market, siret: @market_application.siret,
    application_mode: :solo, user: @market_application.user)
  @market_application.update!(user: @user) if @market_application.user.nil?
  solo_application.update!(user: @market_application.user)
end

Given('a co-traitant of the grouping declared the lot {string}') do |lot_name|
  lot = create(:lot, public_market: @public_market, name: lot_name)
  member_application = create(:market_application, public_market: @public_market, application_mode: :groupement,
    siret: VALID_TEST_SIRETS[0])
  create(:market_application_lot, market_application: member_application, lot:)
  grouping = mandataire_grouping
  create(:grouping_member, :co_traitant, grouping:, market_application: member_application, siret: VALID_TEST_SIRETS[0])
end

Then('the lots section should not show {string}') do |lot_name|
  within(find('#grouping-dashboard-lots', visible: :all)) { expect(page).not_to have_content(lot_name, wait: false) }
end

Then('the co-traitant declared lots column should show {string}') do |lot_name|
  expect(page).to have_selector('table', text: lot_name)
end

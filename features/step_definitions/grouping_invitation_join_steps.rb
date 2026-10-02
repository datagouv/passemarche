# frozen_string_literal: true

When('I visit the co-traitant invitation link for SIRET {string}') do |siret|
  member = GroupingMember.find_by!(siret:)
  visit candidate_grouping_invitation_path(member.invitation_token)
end

Then('I should be on the co-traitant grouping dashboard') do
  member = GroupingMember.co_traitant.last
  expect(page).to have_current_path(
    grouping_dashboard_candidate_market_application_path(member.market_application.identifier),
    ignore_query: true
  )
end

Then('I should see the action {string} on my own row') do |action_label|
  member = GroupingMember.co_traitant.last
  within("#grouping_member_actions_#{member.id}") { expect(page).to have_content(action_label) }
end

Then('the mandataire row should show no action') do
  mandataire = GroupingMember.mandataire.last
  within("#grouping_member_actions_#{mandataire.id}") { expect(page).to have_no_css('a, button') }
end

Then('I should be on the sent sessions page') do
  expect(page).to have_current_path(sent_candidate_sessions_path, ignore_query: true)
end

Then('the SIRET field should be pre-filled with {string} and locked') do |siret|
  expect(page).to have_field(I18n.t('candidate.sessions.new.siret_label'), with: siret, readonly: true)
end

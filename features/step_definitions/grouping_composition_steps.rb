# frozen_string_literal: true

When('I add a co-traitant with SIRET {string} and email {string}') do |siret, email|
  fill_in I18n.t('candidate.grouping_compositions.siret_label'), with: siret
  fill_in I18n.t('candidate.grouping_compositions.email_label'), with: email
  find_button(I18n.t('candidate.grouping_compositions.add_button'), disabled: false).click

  within('#grouping_members_table') { page.has_content?(siret) } || page.has_css?('.fr-error-text')
end

When('I remove the co-traitant {string}') do |siret|
  member = GroupingMember.find_by!(siret:)
  within("form[action='#{grouping_composition_member_candidate_market_application_path(@market_application.identifier, member)}']") do
    click_button I18n.t('candidate.grouping_compositions.remove_button')
  end
end

When('I visit the grouping composition step directly') do
  visit grouping_composition_candidate_market_application_path(@market_application.identifier)
end

Then('I should see {string} in the members table') do |text|
  within('#grouping_members_table') { expect(page).to have_content(text) }
end

Then('I should not see {string} in the members table') do |text|
  within('#grouping_members_table') { expect(page).not_to have_content(text) }
end

Then('the co-traitant {string} status should be {string}') do |siret, status|
  member_row = find('#grouping_members_table').find('tr', text: siret)
  expect(member_row).to have_content(status)
end

Then('I should see an error about the SIRET') do
  expect(page).to have_css('.fr-error-text')
end

Then('I should see an error about the email') do
  expect(page).to have_css('.fr-error-text')
end

Then('the SIRET field should still contain {string}') do |siret|
  expect(page).to have_field(I18n.t('candidate.grouping_compositions.siret_label'), with: siret)
end

Then('the email field should still contain {string}') do |email|
  expect(page).to have_field(I18n.t('candidate.grouping_compositions.email_label'), with: email)
end

Then('the {string} link should be disabled') do |label|
  expect(page).to have_css("a[aria-disabled='true']", text: label)
end

Then('the {string} link should be enabled') do |label|
  expect(page).to have_css("a[aria-disabled='false']", text: label)
end

Then('an invitation email should have been sent for the co-traitant {string}') do |siret|
  member = GroupingMember.find_by!(siret:)
  expect(member.reload.invitation_sent?).to be true
end

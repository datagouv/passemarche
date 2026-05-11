# frozen_string_literal: true

Then('I should see the delete button for my application') do
  expect(page).to have_button(I18n.t('candidate.dashboard.actions.delete'))
end

Then('I should not see the delete button for my application') do
  expect(page).not_to have_button(I18n.t('candidate.dashboard.actions.delete'))
end

When('I click the delete button for my application') do
  find("button[data-fr-opened][aria-controls='deletion-modal-#{@market_application.identifier}']").click
end

Then('I should see the deletion confirmation modal') do
  expect(page).to have_text(I18n.t('candidate.dashboard.application.delete_modal.title'))
  expect(page).to have_text(I18n.t('candidate.dashboard.application.delete_modal.body'))
end

When('I confirm the deletion') do
  within("#deletion-modal-#{@market_application.identifier}") do
    click_button I18n.t('candidate.dashboard.application.delete_modal.confirm')
  end
end

Then('my application should no longer exist') do
  expect(MarketApplication.find_by(id: @market_application.id)).to be_nil
end

# frozen_string_literal: true

When('I fill in the contestation form with a file and text') do
  bloc = find(:xpath, "//div[contains(@class, 'fr-notice') and .//h3[contains(text(), 'liquidation')]]")
  bloc.fill_in 'Décrivez les motifs de votre contestation', with: 'Explication de la contestation.'
  bloc.attach_file('market_attribute_response_file', Rails.root.join('spec/fixtures/files/test.pdf'), make_visible: true) if bloc.has_field?('market_attribute_response_file', type: 'file')
end

When('I visit the attestation motifs exclusion page for my application') do
  visit "/candidate/market_applications/#{@market_application.identifier}/attestation_motifs_exclusion"
end

When('I click the contestation button') do
  btn_text = I18n.t('candidate.market_applications.motifs_exclusion.provide_additional_info_button')
  bloc = find(:xpath, "//div[contains(@class, 'fr-notice') and .//h3[contains(text(), 'liquidation')]]")
  bloc.find(:button, btn_text, visible: :all).click
end

Then('I should see the contestation form') do
  bloc = find(:xpath, "//div[contains(@class, 'fr-notice') and .//h3[contains(text(), 'liquidation')]]")
  expect(bloc).to have_content('Décrivez les motifs de votre contestation')
end

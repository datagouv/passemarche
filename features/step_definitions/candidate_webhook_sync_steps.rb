# frozen_string_literal: true

Given('une candidature associée à cet éditeur exists') do
  public_market = create(:public_market, :completed, editor: @editor)
  @market_application = create(:market_application, public_market:, sync_status: :sync_pending,
    completed_at: Time.zone.now)
  authenticate_as_candidate_for(@market_application)
end

Given('la candidature est en cours de synchronisation') do
  @market_application.update!(sync_status: :sync_processing)
end

Given('la candidature a été synchronisée avec succès') do
  @market_application.update!(sync_status: :sync_completed)
end

Given('la candidature a échoué à se synchroniser') do
  @market_application.update!(sync_status: :sync_failed)
end

Given("l'éditeur a une URL de retour candidat {string}") do |url|
  @editor.update!(candidate_return_url: url)
end

When('je visite la page de statut de synchronisation candidat') do
  visit candidate_sync_status_path(@market_application.identifier)
end

Then('je vois un lien de retour candidat vers {string}') do |base_url|
  expected_href = "#{base_url}?market_identifier=#{@market_application.public_market.identifier}&application_identifier=#{@market_application.identifier}"
  expect(page).to have_link(@editor.name, href: expected_href)
end

Then('je ne vois pas de lien de retour candidat') do
  expect(page).not_to have_link(I18n.t('candidate.sync_status.return_to_editor', editor: @editor.name))
end

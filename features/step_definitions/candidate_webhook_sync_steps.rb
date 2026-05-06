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

When('je visite la page de statut de synchronisation candidat') do
  visit candidate_sync_status_path(@market_application.identifier)
end

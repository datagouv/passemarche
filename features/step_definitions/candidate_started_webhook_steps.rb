# frozen_string_literal: true

Given("l'éditeur reçoit les webhooks sur {string}") do |webhook_url|
  @editor.update!(completion_webhook_url: webhook_url)
  stub_request(:post, webhook_url).to_return(status: 200, body: 'OK')
end

Given('une candidature démarrée puis transmise existe') do
  @market_application = create(:market_application, :completed,
    public_market: @public_market,
    siret: RECANDIDATE_SIRET,
    started_at: 1.day.ago)
end

When("le candidat arrive sur l'étape des informations du marché") do
  @market_application = MarketApplication.find_by!(identifier: @response_body['identifier'])
  authenticate_as_candidate_for(@market_application) unless @candidate_authenticated
  @candidate_authenticated = true
  visit "/candidate/market_applications/#{@market_application.identifier}/market_information"
end

When("le candidat valide l'étape des informations du marché") do
  submit_step
end

Then('la plateforme a reçu {int} fois le statut « en cours » de la candidature') do |count|
  expect(WebMock).to have_requested(:post, @editor.completion_webhook_url)
    .with(body: hash_including(
      'event' => 'market_application.started',
      'market_identifier' => @public_market.identifier,
      'market_application' => {
        'identifier' => @market_application.identifier,
        'siret' => RECANDIDATE_SIRET,
        'status' => 'in_progress'
      }
    )).times(count)
end

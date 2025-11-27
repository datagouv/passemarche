# frozen_string_literal: true

require 'webmock/cucumber'

Given('a market attribute exists for URSSAF attestation vigilance') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  [
    {
      key: 'motifs_exclusion_fiscales_et_sociales_declarations_cotisations_sociales',
      category_key: 'motifs_exclusion_fiscales_et_sociales',
      subcategory_key: 'motifs_exclusion_fiscales_et_sociales'
    },
    {
      key: 'motifs_exclusion_fiscales_et_sociales_travailleurs_handicapes',
      category_key: 'motifs_exclusion_fiscales_et_sociales',
      subcategory_key: 'motifs_exclusion_fiscales_et_sociales'
    }
  ].each do |attrs|
    create(
      :market_attribute,
      :file_upload,
      key: attrs[:key],
      api_name: 'urssaf_attestation_vigilance',
      api_key: 'document',
      category_key: attrs[:category_key],
      subcategory_key: attrs[:subcategory_key],
      public_markets: [@public_market]
    )
  end
end

Given('a market attribute exists for URSSAF travailleurs handicapés') do
  # Step intentionally left blank (completeness)
end

Given(/^a candidate starts an application for this market \(urssaf\)$/) do
  @market_application = create(
    :market_application,
    public_market: @public_market,
    siret: '41816609600069'
  )
end

Given('the URSSAF API will return a valid attestation') do
  %w[
    motifs_exclusion_fiscales_et_sociales_declarations_cotisations_sociales
    motifs_exclusion_fisciales_et_sociales_travailleurs_handicapes
  ].each_with_index do |_field_key, idx|
    document_url = "https://attestation-vigilance-urssaf.fr/TelechargementAttestation.aspx?ID=1569139162#{idx}&B99824D9C764AAE19A862A0AF"

    stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v4/urssaf/unites_legales/418166096/attestation_vigilance\?.*})
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => /Bearer .*/,
          'Content-Type' => 'application/json',
          'Host' => 'staging.entreprise.api.gouv.fr',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(
        status: 200,
        body: {
          data: {
            entity_status: 'ok',
            document_url:,
            document_url_expires_in: 3600
          },
          links: {},
          meta: { api_version: '4.0.0' }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, document_url)
      .to_return(
        status: 200,
        body: '%PDF-1.4 fake attestation content' * 50,
        headers: {
          'Content-Type' => 'application/pdf',
          'Content-Disposition' => 'attachment; filename="attestation_vigilance_acoss.pdf"'
        }
      )
  end
end

Given('the URSSAF API is not available') do
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v4/urssaf/unites_legales/418166096/attestation_vigilance\?.*})
    .to_return(status: 503, body: 'Service Unavailable')
end

Given('the URSSAF API will return an error') do
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v4/urssaf/unites_legales/418166096/attestation_vigilance\?.*})
    .to_return(
      status: 404,
      body: {
        errors: [
          {
            code: '01000',
            title: 'Entité non trouvée',
            detail: "L'entité demandée n'a pas pu être trouvée.",
            status: 404,
            source: {
              parameter: 'siren',
              example: '418166096'
            }
          }
        ],
        meta: { api_version: '4.0.0' }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

When('I visit the exclusion motifs step for {string}') do |_which|
  visit step_candidate_market_application_path(
    identifier: @market_application.identifier,
    id: 'motifs_exclusion_fiscales_et_sociales'
  )
end

When('the API fetches my URSSAF data automatically') do
  FetchUrssafDataJob.perform_now(@market_application.id)
end

When('the API attempts to fetch my URSSAF data') do
  FetchUrssafDataJob.perform_now(@market_application.id)
end

When('I visit the exclusion step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/motifs_exclusion_fiscales_et_sociales"
end

Then('I should see the URSSAF fields with API data available') do
  expect(page).to have_content('Récupéré automatiquement')
end

Then('I should see the attestation documents are downloaded') do
  @market_application.reload

  %w[
    motifs_exclusion_fiscales_et_sociales_declarations_cotisations_sociales
    motifs_exclusion_fiscales_et_sociales_travailleurs_handicapes
  ].each do |field_key|
    response = @market_application.market_attribute_responses
      .joins(:market_attribute)
      .find_by(market_attributes: { key: field_key })

    expect(response).to be_present
    expect(response.documents.attached?).to eq(true)
    expect(response.source).to eq('auto')
  end
end

Then('the fields should be marked as completed from API') do
  expect(page).to have_content('Cotisations sociales')
  expect(page).to have_content('Emploi de travailleurs handicapés')
  expect(page).to have_content('Récupéré automatiquement', count: 2)
  expect(page).to have_content('Cette information a été récupérée automatiquement et ne nécessite pas votre intervention.', count: 2)
end

Then('I should see the attestation filenames displayed') do
  expect(page).to have_content('attestation_vigilance', count: 2)
  expect(page).to have_content('.pdf', count: 2)
end

Then('I should be able to upload a document manually') do
  expect(page).to have_selector('input[type="file"]')
end

Then('I should be able to provide a justification') do
  expect(page).to have_selector('textarea')
end

Then('I should be able to complete the field manually') do
  # File upload fields allow manual completion via file input
  expect(page).to have_selector('input[type="file"]')
end

Then('I should be able to upload supporting documents') do
  expect(page).to have_selector('input[type="file"]')
end

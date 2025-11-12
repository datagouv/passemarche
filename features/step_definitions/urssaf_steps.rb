# frozen_string_literal: true

require 'webmock/cucumber'

Given('a market attribute exists for URSSAF attestation vigilance') do
  @editor ||= create(:editor)
  @public_market ||= create(:public_market, :completed, editor: @editor)

  @market_attribute_cotisations = create(
    :market_attribute,
    :radio_with_justification_required,
    key: 'motifs_exclusion_fiscales_et_sociales_declarations_cotisations_sociales',
    api_name: 'urssaf_attestation_vigilance',
    api_key: 'document',
    category_key: 'motifs_exclusion_fiscales_et_sociales',
    subcategory_key: 'obligations_fiscales_et_sociales'
  )
  @market_attribute_handicapes = create(
    :market_attribute,
    :radio_with_justification_required,
    key: 'motifs_exclusion_fiscales_et_sociales_travailleurs_handicapes',
    api_name: 'urssaf_attestation_vigilance',
    api_key: 'document',
    category_key: 'motifs_exclusion_fiscales_et_sociales',
    subcategory_key: 'obligations_fiscales_et_sociales'
  )
  @public_market.market_attributes << @market_attribute_cotisations unless @public_market.market_attributes.include?(@market_attribute_cotisations)
  @public_market.market_attributes << @market_attribute_handicapes unless @public_market.market_attributes.include?(@market_attribute_handicapes)
end

Given('the URSSAF API will return a valid attestation') do
  %w[
    motifs_exclusion_fiscales_et_sociales_declarations_cotisations_sociales
    motifs_exclusion_fiscales_et_sociales_travailleurs_handicapes
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

Given('the URSSAF API will return a refusal status') do
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
          entity_status: 'refus_de_delivrance'
        },
        links: {},
        meta: { api_version: '4.0.0' }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
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

When('I visit the exclusion motifs step for {string}') do |which|
  subcategory_key = case which
                    when 'obligations_fiscales_et_sociales'
                      'obligations_fiscales_et_sociales'
                    else
                      raise "Unknown exclusion motifs step: #{which}"
                    end
  visit step_candidate_market_application_path(
    identifier: @market_application.identifier,
    id: subcategory_key
  )
end

When('the API fetches my URSSAF data automatically') do
  FetchUrssafDataJob.perform_now(@market_application.id)
end

When('the API attempts to fetch my URSSAF data') do
  FetchUrssafDataJob.perform_now(@market_application.id)
end

Then('I should see the URSSAF fields with API data available') do
  expect(page).to have_content('Données récupérées automatiquement')
end

Then('I should see the attestation documents are downloaded') do
  %w[
    motifs_exclusion_fiscales_et_sociales_declarations_cotisations_sociales
    motifs_exclusion_fiscales_et_sociales_travailleurs_handicapes
  ].each do |field_key|
    response = @market_application.market_attribute_responses
      .joins(:market_attribute)
      .find_by(market_attributes: { key: field_key })
    expect(response).to be_present
    expect(response.documents).to be_attached
    expect(response.source).to eq('auto')
  end
end

Then('the fields should be marked as completed from API') do
  expect(page).to have_selector('.api-success-indicator', count: 2)
  expect(page).to have_content('Complété automatiquement')
end

Then('I should see the attestation filenames displayed') do
  expect(page).to have_content('attestation_vigilance', count: 2)
  expect(page).to have_content('.pdf', count: 2)
end

Then('I should see an indication that no attestation is available') do
  expect(page).to have_selector('input[type="radio"][value="yes"]')
  expect(page).to have_selector('input[type="radio"][value="no"]')
end

Then('I should be able to upload a document manually') do
  expect(page).to have_selector('input[type="file"]')
end

Then('I should be able to provide a justification') do
  expect(page).to have_selector('textarea')
end

Then('I should see a fallback to manual entry') do
  expect(page).to have_selector('input[type="radio"][value="yes"]')
  expect(page).to have_selector('input[type="radio"][value="no"]')
end

Then('I should be able to complete the field manually') do
  expect(page).to have_selector('input[type="radio"][value="yes"]')
  expect(page).to have_selector('input[type="radio"][value="no"]')
end

Then('I should be able to select {string} for the exclusion question') do |answer|
  value = answer.downcase == 'oui' ? 'yes' : 'no'
  expect(page).to have_selector("input[type='radio'][value='#{value}']")
end

Then('I should be able to upload supporting documents') do
  expect(page).to have_selector('input[type="file"]')
end

Then('I should be able to provide written justification') do
  expect(page).to have_selector('textarea')
end

Given('a market attribute exists for URSSAF travailleurs handicapés') do
end

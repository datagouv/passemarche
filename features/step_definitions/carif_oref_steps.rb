# frozen_string_literal: true

Given('a public market with CARIF-OREF fields exists') do
  @public_market = create(:public_market, :completed)

  @qualiopi_attribute = create(:market_attribute,
    key: 'capacites_techniques_professionnelles_certificats_qualiopi_france',
    input_type: 'inline_file_upload',
    api_name: 'carif_oref',
    api_key: 'qualiopi',
    category_key: 'capacites_techniques_professionnelles',
    subcategory_key: 'capacites_techniques_professionnelles_certificats')
  @qualiopi_attribute.public_markets << @public_market

  @france_competence_attribute = create(:market_attribute,
    key: 'capacites_techniques_professionnelles_certificats_france_competences',
    input_type: 'inline_url_input',
    api_name: 'carif_oref',
    api_key: 'france_competence',
    category_key: 'capacites_techniques_professionnelles',
    subcategory_key: 'capacites_techniques_professionnelles_certificats')
  @france_competence_attribute.public_markets << @public_market

  # Add contact attribute so we can pass through steps
  @contact_attribute = create(:market_attribute,
    key: 'identite_entreprise_contact_email',
    input_type: 'email_input',
    category_key: 'identite_entreprise',
    subcategory_key: 'identite_entreprise_contact')
  @contact_attribute.public_markets << @public_market

  @contact_phone_attribute = create(:market_attribute,
    key: 'identite_entreprise_contact_telephone',
    input_type: 'phone_input',
    category_key: 'identite_entreprise',
    subcategory_key: 'identite_entreprise_contact')
  @contact_phone_attribute.public_markets << @public_market
end

Given('the CARIF-OREF API returns Qualiopi certification data') do
  stub_carif_oref_api_success_qualiopi
  stub_other_apis_minimal
end

Given('the CARIF-OREF API returns France Competences habilitations') do
  stub_carif_oref_api_success_france_competences
  stub_other_apis_minimal
end

Given('the CARIF-OREF API returns an error') do
  stub_carif_oref_api_failure
  stub_other_apis_minimal
end

When('I start an application for the CARIF-OREF market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '12000101100010')
end

When('I fill in the SIRET for CARIF-OREF application') do
  visit "/candidate/market_applications/#{@market_application.identifier}/company_identification"
  # SIRET is now locked - just click continue
  click_button 'Continuer'
end

When('all APIs complete for CARIF-OREF') do
  expect(page).to have_current_path("/candidate/market_applications/#{@market_application.identifier}/api_data_recovery_status")

  Timeout.timeout(10) do
    loop do
      sleep 0.5
      @market_application.reload
      api_status = @market_application.api_fetch_status || {}
      carif_oref_status = api_status.dig('carif_oref', 'status')

      break if %w[completed failed].include?(carif_oref_status)
    end
  end

  click_button 'Continuer'
end

When('all APIs complete for CARIF-OREF with failures') do
  expect(page).to have_current_path("/candidate/market_applications/#{@market_application.identifier}/api_data_recovery_status")

  Timeout.timeout(10) do
    loop do
      sleep 0.5
      @market_application.reload
      api_status = @market_application.api_fetch_status || {}
      carif_oref_status = api_status.dig('carif_oref', 'status')

      break if carif_oref_status == 'failed'
    end
  end

  click_button 'Continuer'
end

Then('the market application should have Qualiopi data stored') do
  @market_application.reload
  qualiopi_response = @market_application.market_attribute_responses.joins(:market_attribute)
    .where(market_attributes: { api_key: 'qualiopi' }).first

  expect(qualiopi_response).not_to be_nil
  expect(qualiopi_response.source).to eq('auto')
  expect(qualiopi_response.value).to include('certification_qualiopi')
  expect(qualiopi_response.value['certification_qualiopi']['action_formation']).to be true
end

Then('the market application should have France Competences data stored') do
  @market_application.reload
  france_competence_response = @market_application.market_attribute_responses.joins(:market_attribute)
    .where(market_attributes: { api_key: 'france_competence' }).first

  expect(france_competence_response).not_to be_nil
  expect(france_competence_response.source).to eq('auto')
  expect(france_competence_response.value).to include('habilitations')
  expect(france_competence_response.value['habilitations'].first['code']).to eq('RNCP10013')
end

Then('the market application should have manual fallback responses for CARIF-OREF') do
  @market_application.reload
  qualiopi_response = @market_application.market_attribute_responses.joins(:market_attribute)
    .where(market_attributes: { api_key: 'qualiopi' }).first
  france_competence_response = @market_application.market_attribute_responses.joins(:market_attribute)
    .where(market_attributes: { api_key: 'france_competence' }).first

  expect(qualiopi_response).not_to be_nil
  expect(qualiopi_response.source).to eq('manual_after_api_failure')

  expect(france_competence_response).not_to be_nil
  expect(france_competence_response.source).to eq('manual_after_api_failure')
end

def stub_carif_oref_api_success_qualiopi
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/carif_oref/etablissements/.*/certifications_qualiopi_france_competences})
    .to_return(
      status: 200,
      body: {
        data: {
          siret: '12000101100010',
          declarations_activites_etablissement: [
            {
              numero_de_declaration: '11910843391',
              actif: true,
              date_derniere_declaration: '2021-01-30',
              certification_qualiopi: {
                action_formation: true,
                bilan_competences: true,
                validation_acquis_experience: false,
                apprentissage: true,
                obtention_via_unite_legale: true
              },
              specialites: {
                specialite_1: { code: '313', libelle: 'Finances, banque, assurances' },
                specialite_2: { code: '326', libelle: 'Informatique' }
              }
            }
          ],
          habilitations_france_competence: []
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_carif_oref_api_success_france_competences
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/carif_oref/etablissements/.*/certifications_qualiopi_france_competences})
    .to_return(
      status: 200,
      body: {
        data: {
          siret: '12000101100010',
          declarations_activites_etablissement: [],
          habilitations_france_competence: [
            {
              code: 'RNCP10013',
              actif: true,
              date_actif: '2020-01-30',
              date_fin_enregistrement: '2030-01-30',
              date_decision: '2020-01-30',
              habilitation_pour_former: true,
              habilitation_pour_organiser_l_evaluation: true
            },
            {
              code: 'RS12345',
              actif: false,
              date_actif: '2019-01-30',
              date_fin_enregistrement: '2025-01-30',
              date_decision: '2019-01-30',
              habilitation_pour_former: true,
              habilitation_pour_organiser_l_evaluation: false
            }
          ]
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_carif_oref_api_failure
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/carif_oref/etablissements/.*/certifications_qualiopi_france_competences})
    .to_return(
      status: 404,
      body: { errors: [{ detail: 'Établissement non trouvé' }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_other_apis_minimal
  # Stub INSEE API
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/.*})
    .to_return(
      status: 200,
      body: {
        data: {
          denomination: 'Test Company CARIF-OREF',
          category_entreprise: 'PME'
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

  # Stub RNE API (minimal)
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/inpi/rne/unites_legales/.*/extrait_rne})
    .to_return(
      status: 404,
      body: { errors: [] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

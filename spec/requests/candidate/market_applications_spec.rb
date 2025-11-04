# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::MarketApplications', type: :request do
  include ActiveJob::TestHelper
  include ApiResponses::InseeResponses
  include ApiResponses::RneResponses
  include ApiResponses::DgfipResponses
  include ApiResponses::QualibatResponses

  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:completed_market_application) { create(:market_application, :completed, public_market:, siret: '73282932000074') }

  before do
    create(:market_attribute, key: 'company_name', category_key: 'identite_entreprise', subcategory_key: 'market_information', public_markets: [public_market])
    create(:market_attribute, key: 'exclusion_question', category_key: 'exclusion_criteria', subcategory_key: 'exclusion_criteria', public_markets: [public_market])
    create(:market_attribute, key: 'turnover', category_key: 'economic_capacities', subcategory_key: 'economic_capacities', public_markets: [public_market])
    create(:market_attribute, key: 'certificates', category_key: 'technical_capacities', subcategory_key: 'technical_capacities', public_markets: [public_market])
  end

  STEPS = %i[
    company_identification
    api_data_recovery_status
    market_information
    exclusion_criteria
    economic_capacities
    technical_capacities
    summary
  ].freeze

  before do
    # Mock API credentials to prevent leaking real tokens in CI logs
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(
        base_url: 'https://entreprise.api.gouv.fr/',
        token: 'test_token_123'
      )
    )

    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')

    # Stub ActiveStorage download to prevent file system access in tests
    allow_any_instance_of(ActiveStorage::Blob).to receive(:download).and_return('fake pdf content')

    allow(Zip::OutputStream).to receive(:write_buffer).and_yield(double('zip_stream', put_next_entry: nil, write: nil)).and_return(double('zip_buffer', string: 'fake zip content'))

    # Stub INSEE API calls for general tests (default SIRET)
    stub_request(:get, %r{https://.*entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/})
      .with(
        query: hash_including(
          'context' => 'Candidature marché public',
          'recipient' => '13002526500013'
        )
      )
      .to_return(
        status: 200,
        body: insee_etablissement_success_response(siret: '73282932000074'),
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub RNE API calls for general tests
    stub_request(:get, %r{https://.*entreprise\.api\.gouv\.fr/v3/inpi/rne/unites_legales/\d+/extrait_rne})
      .with(
        query: hash_including(
          'context' => 'Candidature marché public',
          'recipient' => '13002526500013'
        )
      )
      .to_return(
        status: 200,
        body: '{"data": {"identite_entreprise": {"adresse_siege_social": {}}}, "dirigeants_et_associes": []}',
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub GenerateDocumentsPackage to avoid ActiveStorage download issues in tests
    allow_any_instance_of(GenerateDocumentsPackage).to receive(:call) do |instance|
      # Attach a fake documents package
      instance.context.market_application.documents_package.attach(
        io: StringIO.new('fake zip content'),
        filename: "documents_package_FT#{instance.context.market_application.identifier}.zip",
        content_type: 'application/zip'
      )
      instance.context.documents_package = instance.context.market_application.documents_package
      instance.context
    end
  end

  describe 'GET /candidate/market_applications/:identifier/:step' do
    STEPS.each_with_index do |step, idx|
      context 'when application is not completed' do
        it "redirects correctly after #{step} step" do
          patch "/candidate/market_applications/#{market_application.identifier}/#{step}"
          expect_correct_redirect_for_step(step, idx, market_application.identifier)
        end
      end

      context 'when application is completed' do
        it "redirects to sync status from #{step} step when performing get requests" do
          get "/candidate/market_applications/#{completed_market_application.identifier}/#{step}"
          expect(response).to redirect_to(candidate_sync_status_path(completed_market_application.identifier))
        end

        it "redirects to sync status from #{step} step when performing patch requests" do
          patch "/candidate/market_applications/#{completed_market_application.identifier}/#{step}"
          expect(response).to redirect_to(candidate_sync_status_path(completed_market_application.identifier))
        end
      end
    end

    it 'returns 404 for non-existent market application' do
      get '/candidate/market_applications/NONEXISTENT/company_identification'

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('La candidature recherchée n\'a pas été trouvée')
    end

    it 'displays company_identification step' do
      get "/candidate/market_applications/#{market_application.identifier}/company_identification"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Bienvenue,')
      expect(response.body).to include(market_application.siret)
    end
  end

  describe 'PATCH /candidate/market_applications/:identifier/company_identification' do
    let(:next_step) { 'api_data_recovery_status' }

    context 'with valid SIRET on company_identification' do
      it 'saves the SIRET and redirects to next step' do
        valid_siret = '73282932000074'

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: valid_siret } }

        expect(response).to redirect_to(
          "/candidate/market_applications/#{market_application.identifier}/#{next_step}"
        )

        market_application.reload
        expect(market_application.siret).to eq(valid_siret)
      end

      it 'accepts La Poste SIRET (special case)' do
        la_poste_siret = '35600000000048'

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: la_poste_siret } }

        expect(response).to redirect_to(
          "/candidate/market_applications/#{market_application.identifier}/#{next_step}"
        )

        market_application.reload
        expect(market_application.siret).to eq(la_poste_siret)
      end

      it 'allows empty SIRET and saves as empty string' do
        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: '' } }

        expect(response).to redirect_to(
          "/candidate/market_applications/#{market_application.identifier}/#{next_step}"
        )

        market_application.reload
        expect(market_application.siret).to eq('')
      end
    end

    context 'with invalid SIRET on company_identification' do
      it 'does not save invalid SIRET and renders the form with error' do
        invalid_siret = '12345678901234'

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: invalid_siret } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Le numéro de SIRET saisi est invalide')

        market_application.reload
        expect(market_application.siret).not_to eq(invalid_siret)
        expect(market_application.siret).to eq('73282932000074') # Original value unchanged
      end

      it 'does not save SIRET with wrong format' do
        wrong_format_siret = '123ABC'

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: wrong_format_siret } }

        expect(response).to have_http_status(:unprocessable_content)
        # The actual error shows as translated message in the HTML
        expect(response.body).to include('Le numéro SIRET doit être composé de 14 chiffres valides')

        market_application.reload
        expect(market_application.siret).not_to eq(wrong_format_siret)
      end

      it 'does not save SIRET with wrong length' do
        wrong_length_siret = '123456'

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: wrong_length_siret } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Le numéro SIRET doit être composé de 14 chiffres valides')

        market_application.reload
        expect(market_application.siret).not_to eq(wrong_length_siret)
      end
    end

    context 'without params on company_identification' do
      it 'does not modify SIRET when no parameter provided' do
        original_siret = market_application.siret

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification"

        expect(response).to redirect_to("/candidate/market_applications/#{market_application.identifier}/#{next_step}")

        market_application.reload
        expect(market_application.siret).to eq(original_siret)
      end
    end

    context 'with INSEE API integration' do
      let(:valid_siret) { '41816609600069' }
      let(:api_url) { "https://entreprise.api.gouv.fr/v3/insee/sirene/etablissements/#{valid_siret}" }
      let(:token) { 'test_token_123' }
      let(:api_entreprise_credentials) do
        OpenStruct.new(
          base_url: 'https://entreprise.api.gouv.fr/',
          token:
        )
      end

      let!(:siret_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_siret',
          api_name: 'insee',
          api_key: 'siret',
          public_markets: [public_market])
      end

      let!(:category_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_categorie',
          api_name: 'insee',
          api_key: 'category',
          public_markets: [public_market])
      end

      let!(:qualibat_attribute) do
        create(:market_attribute, :inline_file_upload, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_qualibat',
          api_name: 'qualibat',
          api_key: 'document',
          public_markets: [public_market])
      end

      before do
        # Credentials are already mocked in the main before block, no need to re-mock

        stub_request(:get, api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: insee_etablissement_success_response(siret: valid_siret),
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub RNE API call
        siren = valid_siret[0..8]
        rne_api_url = "https://entreprise.api.gouv.fr/v3/inpi/rne/unites_legales/#{siren}/extrait_rne"
        stub_request(:get, rne_api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: rne_extrait_success_response(siren:),
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Qualibat API call
        qualibat_api_url = "https://entreprise.api.gouv.fr/v4/qualibat/etablissements/#{valid_siret}/certification_batiment"
        stub_request(:get, qualibat_api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: qualibat_success_response,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub DGFIP API call
        dgfip_api_url = "https://entreprise.api.gouv.fr/v4/dgfip/unites_legales/#{siren}/attestation_fiscale"
        stub_request(:get, dgfip_api_url)
          .with(
            query: hash_including(
              'context' => 'Candidature marché public',
              'recipient' => '13002526500013'
            ),
            headers: { 'Authorization' => "Bearer #{token}" }
          )
          .to_return(
            status: 200,
            body: dgfip_attestation_fiscale_success_response(siren:),
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub DGFIP document download
        dgfip_document_url = "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-attestation_fiscale_dgfip.pdf"
        stub_request(:get, dgfip_document_url)
          .to_return(
            status: 200,
            body: '%PDF-1.4 test document',
            headers: { 'Content-Type' => 'application/pdf' }
          )

        # Stub Qualibat document download
        qualibat_document_url = 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v4_qualibat_certifications_batiment/exemple-qualibat.pdf'
        stub_request(:get, qualibat_document_url)
          .to_return(
            status: 200,
            body: '%PDF-1.4 qualibat test document with enough bytes to pass minimum size validation requiring at least 100 bytes total',
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'calls INSEE API and redirects to status page' do
        # Perform jobs as they're enqueued
        perform_enqueued_jobs do
          # First submit SIRET - this enqueues background jobs
          patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
            params: { market_application: { siret: valid_siret } }
        end

        expect(response).to redirect_to(
          "/candidate/market_applications/#{market_application.identifier}/api_data_recovery_status"
        )

        market_application.reload
        expect(market_application.siret).to eq(valid_siret)
      end

      it 'populates market_attribute_responses with API data' do
        perform_enqueued_jobs do
          patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
            params: { market_application: { siret: valid_siret } }
        end

        market_application.reload

        # Verify API data was populated by jobs
        siret_response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
        category_response = market_application.market_attribute_responses.find_by(market_attribute: category_attribute)
        qualibat_response = market_application.market_attribute_responses.find_by(market_attribute: qualibat_attribute)

        expect(siret_response.text).to eq('41816609600069')
        expect(category_response.text).to eq('PME')
        expect(qualibat_response.documents).to be_attached
        expect(qualibat_response.documents.first.filename.to_s).to eq('exemple-qualibat.pdf')
      end

      it 'updates API fetch status correctly' do
        perform_enqueued_jobs do
          patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
            params: { market_application: { siret: valid_siret } }
        end

        market_application.reload

        # Verify API statuses in JSONB (only for APIs with market attributes)
        expect(market_application.api_fetch_status['insee']['status']).to eq('completed')
        expect(market_application.api_fetch_status['insee']['fields_filled']).to eq(2)
        expect(market_application.api_fetch_status['qualibat']['status']).to eq('completed')
        expect(market_application.api_fetch_status['qualibat']['fields_filled']).to eq(1)
        expect(market_application.api_fetch_status['rne']).to be_nil
        expect(market_application.api_fetch_status['dgfip']).to be_nil
      end

      it 'allows navigation from status page to next step' do
        perform_enqueued_jobs do
          patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
            params: { market_application: { siret: valid_siret } }
        end

        # Then navigate through the status page
        patch "/candidate/market_applications/#{market_application.identifier}/api_data_recovery_status"

        expect(response).to redirect_to(
          "/candidate/market_applications/#{market_application.identifier}/market_information"
        )
      end

      context 'when INSEE API fails' do
        before do
          stub_request(:get, api_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 404,
              body: insee_etablissement_not_found_response,
              headers: { 'Content-Type' => 'application/json' }
            )

          # Also stub RNE API call
          siren = valid_siret[0..8]
          rne_api_url = "https://entreprise.api.gouv.fr/v3/inpi/rne/unites_legales/#{siren}/extrait_rne"
          stub_request(:get, rne_api_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 404,
              body: rne_extrait_not_found_response,
              headers: { 'Content-Type' => 'application/json' }
            )

          qualibat_api_url = "https://entreprise.api.gouv.fr/v4/qualibat/etablissements/#{valid_siret}/certification_batiment"
          stub_request(:get, qualibat_api_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 404,
              body: qualibat_not_found_response,
              headers: { 'Content-Type' => 'application/json' }
            )

          # Also stub DGFIP API call to fail
          dgfip_api_url = "https://entreprise.api.gouv.fr/v4/dgfip/unites_legales/#{siren}/attestation_fiscale"
          stub_request(:get, dgfip_api_url)
            .with(
              query: hash_including(
                'context' => 'Candidature marché public',
                'recipient' => '13002526500013'
              ),
              headers: { 'Authorization' => "Bearer #{token}" }
            )
            .to_return(
              status: 404,
              body: dgfip_attestation_fiscale_not_found_response,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'still saves SIRET and creates responses marked as manual_after_api_failure' do
          # Perform jobs as they're enqueued
          perform_enqueued_jobs do
            # First submit SIRET - this enqueues background jobs
            patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
              params: { market_application: { siret: valid_siret } }
          end

          expect(response).to redirect_to(
            "/candidate/market_applications/#{market_application.identifier}/api_data_recovery_status"
          )

          market_application.reload
          expect(market_application.siret).to eq(valid_siret)

          # Verify API failure was handled by jobs
          expect(market_application.market_attribute_responses.count).to eq(3)

          # Verify responses are marked as manual_after_api_failure
          responses = market_application.market_attribute_responses.reload
          expect(responses.map(&:source).uniq).to eq(['manual_after_api_failure'])

          # Verify API statuses in JSONB show failures (only for APIs with market attributes)
          expect(market_application.api_fetch_status['insee']['status']).to eq('failed')
          expect(market_application.api_fetch_status['qualibat']['status']).to eq('failed')
          expect(market_application.api_fetch_status['rne']).to be_nil
          expect(market_application.api_fetch_status['dgfip']).to be_nil

          # Then navigate through the status page
          patch "/candidate/market_applications/#{market_application.identifier}/api_data_recovery_status"

          expect(response).to redirect_to(
            "/candidate/market_applications/#{market_application.identifier}/market_information"
          )
        end
      end
    end

    describe 'PATCH summary step' do
      let(:summary_path) { step_candidate_market_application_path(market_application.identifier, :summary) }

      context 'when completing the wizard' do
        before do
          patch summary_path
        end

        it 'redirects to root' do
          expect(response).to redirect_to(candidate_sync_status_path(market_application.identifier))
        end

        it 'completes the market' do
          market_application.reload
          expect(market_application).to be_completed
        end

        it 'enqueues webhook sync job' do
          expect(MarketApplicationWebhookJob).to have_been_enqueued.with(
            market_application.id,
            request_host: 'www.example.com',
            request_protocol: 'http://'
          )
        end
      end
    end
  end

  private

  def expect_correct_redirect_for_step(step, idx, identifier)
    if step == :summary
      expect(response).to redirect_to(candidate_sync_status_path(identifier))
    else
      next_step = STEPS[idx + 1]
      expect(response).to redirect_to("/candidate/market_applications/#{identifier}/#{next_step}") if next_step
    end
  end
end

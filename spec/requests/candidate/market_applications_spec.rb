# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::MarketApplications', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:completed_market_application) { create(:market_application, :completed, public_market:, siret: '73282932000074') }

  # Create market attributes to match the expected wizard steps
  before do
    create(:market_attribute, key: 'company_name', category_key: 'market_and_company_information', public_markets: [public_market])
    create(:market_attribute, key: 'exclusion_question', category_key: 'exclusion_criteria', public_markets: [public_market])
    create(:market_attribute, key: 'turnover', category_key: 'economic_capacities', public_markets: [public_market])
    create(:market_attribute, key: 'certificates', category_key: 'technical_capacities', public_markets: [public_market])
  end

  STEPS = %i[
    company_identification
    market_and_company_information
    exclusion_criteria
    economic_capacities
    technical_capacities
    summary
  ].freeze

  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
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
    let(:next_step) { 'market_and_company_information' }

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
        expect(response.body).to include('doit être un numéro SIRET valide de 14 chiffres')

        market_application.reload
        expect(market_application.siret).not_to eq(wrong_format_siret)
      end

      it 'does not save SIRET with wrong length' do
        wrong_length_siret = '123456'

        patch "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: wrong_length_siret } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('doit être un numéro SIRET valide de 14 chiffres')

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

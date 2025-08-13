# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::MarketApplications', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor: editor) }
  let(:market_application) { create(:market_application, public_market: public_market, siret: '73282932000074') }

  describe 'GET /candidate/market_applications/:identifier/:step' do
    it 'displays company_identification step' do
      get "/candidate/market_applications/#{market_application.identifier}/company_identification"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Bienvenue,')
      expect(response.body).to include(market_application.siret)
    end

    it 'returns 404 for non-existent market application' do
      get '/candidate/market_applications/NONEXISTENT/company_identification'

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('La candidature recherchée n\'a pas été trouvée')
    end
  end

  describe 'PUT /candidate/market_applications/:identifier/:step' do
    context 'with valid SIRET' do
      it 'saves the SIRET and redirects to finish' do
        valid_siret = '73282932000074'

        put "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: valid_siret } }

        expect(response).to redirect_to(root_path)

        market_application.reload
        expect(market_application.siret).to eq(valid_siret)
      end

      it 'accepts La Poste SIRET (special case)' do
        la_poste_siret = '35600000000048'

        put "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: la_poste_siret } }

        expect(response).to redirect_to(root_path)

        market_application.reload
        expect(market_application.siret).to eq(la_poste_siret)
      end

      it 'allows empty SIRET and saves as empty string' do
        put "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: '' } }

        expect(response).to redirect_to(root_path)

        market_application.reload
        expect(market_application.siret).to eq('')
      end
    end

    context 'with invalid SIRET' do
      it 'does not save invalid SIRET and renders the form with error' do
        invalid_siret = '12345678901234'

        put "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: invalid_siret } }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Le numéro de SIRET saisi est invalide')

        market_application.reload
        expect(market_application.siret).not_to eq(invalid_siret)
        expect(market_application.siret).to eq('73282932000074') # Original value unchanged
      end

      it 'does not save SIRET with wrong format' do
        wrong_format_siret = '123ABC'

        put "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: wrong_format_siret } }

        expect(response).to have_http_status(:success)
        # The actual error shows as translated message in the HTML
        expect(response.body).to include('doit être un numéro SIRET valide de 14 chiffres')

        market_application.reload
        expect(market_application.siret).not_to eq(wrong_format_siret)
      end

      it 'does not save SIRET with wrong length' do
        wrong_length_siret = '123456'

        put "/candidate/market_applications/#{market_application.identifier}/company_identification",
          params: { market_application: { siret: wrong_length_siret } }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('doit être un numéro SIRET valide de 14 chiffres')

        market_application.reload
        expect(market_application.siret).not_to eq(wrong_length_siret)
      end
    end

    context 'without params' do
      it 'does not modify SIRET when no parameter provided' do
        original_siret = market_application.siret

        put "/candidate/market_applications/#{market_application.identifier}/company_identification"

        expect(response).to redirect_to(root_path)

        market_application.reload
        expect(market_application.siret).to eq(original_siret)
      end
    end
  end
end

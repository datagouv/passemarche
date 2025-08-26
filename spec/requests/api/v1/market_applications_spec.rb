# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::MarketApplications', type: :request do
  let(:editor) { create(:editor, :authorized_and_active) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:access_token) { oauth_access_token_for(editor) }

  describe 'POST /api/v1/public_markets/:public_market_id/market_applications' do
    let(:valid_siret) { '73282932000074' }
    let(:invalid_siret) { '12345678901234' }

    let(:valid_params) do
      {
        market_application: {
          siret: valid_siret
        }
      }
    end

    it 'creates market application successfully' do
      post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
        params: valid_params,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:created)
      json_response = response.parsed_body
      expect(json_response['identifier']).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      expect(json_response['application_url']).to include('/candidate/market_applications/')
      expect(json_response['application_url']).to include('/company_identification')
    end

    it 'creates market application in database' do
      expect do
        post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
          params: valid_params,
          headers: { 'Authorization' => "Bearer #{access_token}" },
          as: :json
      end.to change(MarketApplication, :count).by(1)

      application = MarketApplication.last
      expect(application.public_market).to eq(public_market)
      expect(application.siret).to eq(valid_siret)
    end

    it 'returns error when public market not found' do
      post '/api/v1/public_markets/NONEXISTENT/market_applications',
        params: valid_params,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:not_found)
      json_response = response.parsed_body
      expect(json_response['error']).to eq('Public market not found')
    end

    it 'returns error when public market belongs to another editor' do
      other_editor = create(:editor)
      other_market = create(:public_market, :completed, editor: other_editor)

      post "/api/v1/public_markets/#{other_market.identifier}/market_applications",
        params: valid_params,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns validation errors for invalid SIRET' do
      invalid_params = {
        market_application: {
          siret: invalid_siret
        }
      }

      post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
        params: invalid_params,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json_response = response.parsed_body
      expect(json_response['errors']['siret']).to include('Le numéro de SIRET saisi est invalide ou non reconnu, veuillez vérifier votre saisie.')
    end

    it 'accepts La Poste SIRET (special case)' do
      la_poste_params = {
        market_application: {
          siret: '35600000000048'
        }
      }

      post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
        params: la_poste_params,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:created)
      json_response = response.parsed_body
      expect(json_response['identifier']).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end

    it 'requires authentication' do
      post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
        params: valid_params,
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

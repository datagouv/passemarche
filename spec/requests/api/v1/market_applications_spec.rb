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

    it 'creates market application with provider_user_id' do
      params_with_provider = {
        market_application: {
          siret: valid_siret,
          provider_user_id: 'candidate-user-7'
        }
      }

      post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
        params: params_with_provider,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:created)
      application = MarketApplication.last
      expect(application.provider_user_id).to eq('candidate-user-7')
    end

    it 'returns validation error when provider_user_id exceeds 255 characters' do
      long_provider_params = {
        market_application: {
          siret: valid_siret,
          provider_user_id: 'a' * 256
        }
      }

      post "/api/v1/public_markets/#{public_market.identifier}/market_applications",
        params: long_provider_params,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json_response = response.parsed_body
      expect(json_response['errors']).to have_key('provider_user_id')
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

  describe 'GET /api/v1/market_applications/:id/documents_package' do
    let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }

    before do
      allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
      allow(Zip::OutputStream).to receive(:write_buffer).and_yield(double('zip_stream', put_next_entry: nil, write: nil)).and_return(double('zip_buffer', string: 'fake zip content'))
    end

    context 'when application is completed' do
      before do
        CompleteMarketApplication.call(market_application:)
        market_application.reload
      end

      it 'downloads documents package successfully' do
        get "/api/v1/market_applications/#{market_application.identifier}/documents_package",
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/zip')
        expect(response.headers['Content-Disposition']).to include("documents_package_FT#{market_application.identifier}.zip")
        expect(response.body).to eq('fake zip content')
      end
    end

    context 'when application is not completed' do
      it 'returns error' do
        get "/api/v1/market_applications/#{market_application.identifier}/documents_package",
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:unprocessable_content)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Application not completed')
      end
    end

    context 'when documents package is not available' do
      before do
        market_application.complete!
      end

      it 'returns error' do
        get "/api/v1/market_applications/#{market_application.identifier}/documents_package",
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Documents package not available')
      end
    end

    context 'when market application belongs to another editor' do
      let(:other_editor) { create(:editor) }
      let(:other_market) { create(:public_market, :completed, editor: other_editor) }
      let(:other_application) { create(:market_application, public_market: other_market, siret: '73282932000074') }

      before do
        CompleteMarketApplication.call(market_application: other_application)
        other_application.reload
      end

      it 'returns error' do
        get "/api/v1/market_applications/#{other_application.identifier}/documents_package",
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Market application not found')
      end
    end

    context 'when market application does not exist' do
      it 'returns error' do
        get '/api/v1/market_applications/NONEXISTENT/documents_package',
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Market application not found')
      end
    end

    it 'requires authentication' do
      get "/api/v1/market_applications/#{market_application.identifier}/documents_package"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

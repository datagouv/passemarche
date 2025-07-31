# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API::V1::PublicMarkets', type: :request do
  let(:editor) do
    Editor.create!(
      name: 'Test Editor',
      client_id: 'test_client_id',
      client_secret: 'test_client_secret',
      authorized: true,
      active: true
    )
  end

  let(:access_token) do
    editor.ensure_doorkeeper_application!
    Doorkeeper::AccessToken.create!(
      application: editor.doorkeeper_application,
      scopes: 'api_access'
    )
  end

  let!(:supplies_market_type) { create(:market_type, code: 'supplies') }
  let!(:defense_market_type) { create(:market_type, :defense) }

  describe 'POST /api/v1/public_markets' do
    let(:market_params) do
      {
        public_market: {
          name: 'Test Market Name',
          lot_name: 'Test Lot Name',
          deadline: 1.month.from_now.iso8601,
          market_type_codes: ['supplies']
        }
      }
    end

    context 'with valid OAuth token' do
      before do
        post '/api/v1/public_markets',
          params: market_params.to_json,
          headers: {
            'Authorization' => "Bearer #{access_token.token}",
            'Content-Type' => 'application/json'
          }
      end

      it 'creates a new public market' do
        expect(response).to have_http_status(:created)
      end

      it 'returns the public market identifier' do
        json_response = response.parsed_body
        expect(json_response['identifier']).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end

      it 'returns the configuration URL' do
        json_response = response.parsed_body
        identifier = json_response['identifier']
        expected_url = "http://www.example.com/buyer/public_markets/#{identifier}/configure"
        expect(json_response['configuration_url']).to eq(expected_url)
      end

      it 'associates the market with the correct editor' do
        json_response = response.parsed_body
        public_market = PublicMarket.find_by(identifier: json_response['identifier'])
        expect(public_market.editor).to eq(editor)
      end
    end

    context 'without OAuth token' do
      before do
        post '/api/v1/public_markets'
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Not authorized')
      end
    end

    context 'with invalid OAuth token' do
      before do
        post '/api/v1/public_markets',
          headers: { 'Authorization' => 'Bearer invalid_token' }
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when editor does not exist for OAuth application' do
      let(:other_application) do
        CustomDoorkeeperApplication.create!(
          name: 'Other App',
          uid: 'other_client_id',
          secret: 'other_secret',
          redirect_uri: '',
          scopes: 'api_access'
        )
      end

      let(:other_access_token) do
        Doorkeeper::AccessToken.create!(
          application: other_application,
          scopes: 'api_access'
        )
      end

      before do
        post '/api/v1/public_markets',
          headers: { 'Authorization' => "Bearer #{other_access_token.token}" }
      end

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns error message' do
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Editor not found')
      end
    end

    context 'with missing required fields' do
      let(:invalid_params) do
        {
          public_market: {
            name: '',
            deadline: '',
            market_type_codes: []
          }
        }
      end

      before do
        post '/api/v1/public_markets',
          params: invalid_params.to_json,
          headers: {
            'Authorization' => "Bearer #{access_token.token}",
            'Content-Type' => 'application/json'
          }
      end

      it 'returns unprocessable entity status' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        json_response = response.parsed_body
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors']).not_to be_empty
      end
    end

    context 'with defense market type' do
      context 'when defense is included with supplies' do
        let(:defense_params) do
          market_params.deep_merge(
            public_market: { market_type_codes: %w[supplies defense] }
          )
        end

        before do
          post '/api/v1/public_markets',
            params: defense_params.to_json,
            headers: {
              'Authorization' => "Bearer #{access_token.token}",
              'Content-Type' => 'application/json'
            }
        end

        it 'creates market with defense market type' do
          expect(response).to have_http_status(:created)
          json_response = response.parsed_body
          public_market = PublicMarket.find_by(identifier: json_response['identifier'])
          expect(public_market.defense_industry?).to be(true)
          expect(public_market.market_type_codes).to include('supplies', 'defense')
        end
      end

      context 'when defense is provided alone' do
        let(:defense_alone_params) do
          market_params.deep_merge(
            public_market: { market_type_codes: ['defense'] }
          )
        end

        before do
          post '/api/v1/public_markets',
            params: defense_alone_params.to_json,
            headers: {
              'Authorization' => "Bearer #{access_token.token}",
              'Content-Type' => 'application/json'
            }
        end

        it 'returns validation error' do
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['errors']).to include('Market type codes ne peut pas être seul')
        end
      end

      context 'when defense is not provided' do
        before do
          post '/api/v1/public_markets',
            params: market_params.to_json,
            headers: {
              'Authorization' => "Bearer #{access_token.token}",
              'Content-Type' => 'application/json'
            }
        end

        it 'creates market without defense market type' do
          expect(response).to have_http_status(:created)
          json_response = response.parsed_body
          public_market = PublicMarket.find_by(identifier: json_response['identifier'])
          expect(public_market.defense_industry?).to be(false)
        end
      end
    end
  end
end

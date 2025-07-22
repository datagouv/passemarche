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

  describe 'POST /api/v1/public_markets' do
    context 'with valid OAuth token' do
      before do
        post '/api/v1/public_markets',
             headers: { 'Authorization' => "Bearer #{access_token.token}" }
      end

      it 'creates a new public market' do
        expect(response).to have_http_status(:created)
      end

      it 'returns the public market identifier' do
        json_response = JSON.parse(response.body)
        expect(json_response['identifier']).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end

      it 'returns the configuration URL' do
        json_response = JSON.parse(response.body)
        identifier = json_response['identifier']
        expected_url = "http://www.example.com/buyer/public_markets/#{identifier}/configure"
        expect(json_response['configuration_url']).to eq(expected_url)
      end

      it 'associates the market with the correct editor' do
        json_response = JSON.parse(response.body)
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
        json_response = JSON.parse(response.body)
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
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Editor not found')
      end
    end
  end
end

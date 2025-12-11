# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /api/v1/market_applications/:id/attestation', type: :request do
  let(:editor) { create(:editor, :authorized_and_active) }
  let(:other_editor) { create(:editor, :authorized_and_active) }

  let(:access_token) { oauth_access_token_for(editor) }
  let(:other_access_token) { oauth_access_token_for(other_editor) }

  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end

  describe 'with valid OAuth token' do
    let(:public_market) { create(:public_market, :completed, editor:) }
    let(:market_application) { create(:market_application, public_market:) }

    before do
      CompleteMarketApplication.call(market_application:)
    end

    it 'returns the attestation PDF' do
      get "/api/v1/market_applications/#{market_application.identifier}/attestation",
        headers: { 'Authorization' => "Bearer #{access_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include("attestation_FT#{market_application.identifier}.pdf")
    end

    context 'when application is not completed' do
      let(:incomplete_application) { create(:market_application, public_market:, completed_at: nil) }

      it 'returns unprocessable entity' do
        get "/api/v1/market_applications/#{incomplete_application.identifier}/attestation",
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq({ 'error' => 'Application not completed' })
      end
    end

    context 'when attestation is not available' do
      let(:completed_application) { create(:market_application, public_market:, completed_at: 1.hour.ago) }

      it 'returns not found' do
        get "/api/v1/market_applications/#{completed_application.identifier}/attestation",
          headers: { 'Authorization' => "Bearer #{access_token}" }

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq({ 'error' => 'Attestation not available' })
      end
    end
  end

  describe 'with different editor OAuth token' do
    let(:public_market) { create(:public_market, :completed, editor:) }
    let(:market_application) { create(:market_application, public_market:) }

    before do
      CompleteMarketApplication.call(market_application:)
    end

    it 'returns not found (editor does not own this application)' do
      get "/api/v1/market_applications/#{market_application.identifier}/attestation",
        headers: { 'Authorization' => "Bearer #{other_access_token}" }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq({ 'error' => 'Market application not found' })
    end
  end

  describe 'without OAuth token' do
    let(:public_market) { create(:public_market, :completed, editor:) }
    let(:market_application) { create(:market_application, public_market:) }

    it 'returns unauthorized' do
      get "/api/v1/market_applications/#{market_application.identifier}/attestation"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq({ 'error' => 'Not authorized' })
    end
  end

  describe 'with invalid OAuth token' do
    let(:public_market) { create(:public_market, :completed, editor:) }
    let(:market_application) { create(:market_application, public_market:) }

    it 'returns unauthorized' do
      get "/api/v1/market_applications/#{market_application.identifier}/attestation",
        headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq({ 'error' => 'Not authorized' })
    end
  end

  describe 'with non-existent application' do
    it 'returns not found' do
      get '/api/v1/market_applications/nonexistent/attestation',
        headers: { 'Authorization' => "Bearer #{access_token}" }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq({ 'error' => 'Market application not found' })
    end
  end
end

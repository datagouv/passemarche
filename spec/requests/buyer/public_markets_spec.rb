# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Buyer::PublicMarkets', type: :request do
  describe 'GET /buyer/public_markets/:identifier/configure' do
    context 'with valid identifier' do
      let(:public_market) { create(:public_market) }

      before do
        get "/buyer/public_markets/#{public_market.identifier}/configure"
      end

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays the page title with editor name' do
        expect(response.body).to include("#{public_market.editor.name} - Configuration de marché")
      end

      it 'displays the editor name in welcome text' do
        expect(response.body).to include("#{public_market.editor.name} vous permet de mettre en place")
      end

      it 'shows the CTA button with editor name' do
        expect(response.body).to include("Débuter l'activation de #{public_market.editor.name}")
      end
    end

    context 'with invalid identifier' do
      before do
        get '/buyer/public_markets/INVALID-ID/configure'
      end

      it 'returns not found status' do
        expect(response).to have_http_status(:not_found)
      end

      it 'renders plain text error message' do
        expect(response.body).to eq('Public market not found')
      end
    end

    context 'with completed market' do
      let(:public_market) { create(:public_market, :completed) }

      before do
        get "/buyer/public_markets/#{public_market.identifier}/configure"
      end

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays the page title with editor name' do
        expect(response.body).to include("#{public_market.editor.name} - Configuration de marché")
      end

      it 'displays the CTA button with editor name' do
        expect(response.body).to include("Débuter l'activation de #{public_market.editor.name}")
      end
    end
  end
end

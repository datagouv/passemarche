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

      it 'displays market information' do
        expect(response.body).to include('matériels informatiques')
        expect(response.body).to include(public_market.market_type)
      end

      it 'displays deadline information' do
        formatted_deadline = I18n.l(public_market.deadline, format: '%d/%m/%Y %H:%M')
        expect(response.body).to include(formatted_deadline)
      end

      it 'displays lot name when present' do
        expect(response.body).to include(public_market.lot_name) if public_market.lot_name.present?
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

    context 'with public market without lot name' do
      let(:public_market) { create(:public_market, :without_lot) }

      before do
        get "/buyer/public_markets/#{public_market.identifier}/configure"
      end

      it 'does not display lot name section' do
        expect(response.body).not_to include('Nom du lot')
      end
    end
  end
end

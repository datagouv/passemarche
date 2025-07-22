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

      it 'displays the market identifier' do
        expect(response.body).to include(public_market.identifier)
      end

      it 'displays the editor name' do
        expect(response.body).to include(public_market.editor.name)
      end

      it 'shows in progress status for incomplete markets' do
        expect(response.body).to include('In Progress')
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

      it 'shows completed status' do
        expect(response.body).to include('Completed')
      end

      it 'displays completion date' do
        completion_date = public_market.completed_at.strftime('%B %d, %Y')
        expect(response.body).to include(completion_date)
      end
    end
  end
end

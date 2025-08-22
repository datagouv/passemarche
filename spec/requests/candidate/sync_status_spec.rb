# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::SyncStatus', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:, sync_status: 'sync_completed') }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }

  describe 'GET /candidate/market_application/:identifier/sync_status' do
    let(:sync_status_path) { candidate_sync_status_path(market_application.identifier) }

    context 'when requesting HTML' do
      before do
        get sync_status_path
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end

      it 'contains sync status content' do
        expect(response.body).to include('Super page de synchronisation')
      end
    end

    context 'when requesting JSON' do
      before do
        get sync_status_path, headers: { 'Accept' => 'application/json' }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns sync status data' do
        json_response = response.parsed_body

        expect(json_response).to eq('sync_status' => 'sync_pending')
      end

      context 'when sync is completed' do
        before do
          market_application.update!(sync_status: :sync_completed, completed_at: Time.current)
          get sync_status_path, headers: { 'Accept' => 'application/json' }
        end

        it 'returns completed status' do
          json_response = response.parsed_body

          expect(json_response).to eq('sync_status' => 'sync_completed')
        end
      end

      context 'when sync has failed' do
        before do
          market_application.update!(sync_status: :sync_failed, completed_at: Time.current)
          get sync_status_path, headers: { 'Accept' => 'application/json' }
        end

        it 'returns failed status' do
          json_response = response.parsed_body

          expect(json_response).to eq('sync_status' => 'sync_failed')
        end
      end
    end

    context 'with non-existent market' do
      before do
        get buyer_sync_status_path('NON-EXISTENT')
      end

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

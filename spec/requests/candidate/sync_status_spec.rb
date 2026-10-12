# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::SyncStatus', type: :request do
  let(:editor) { create(:editor, candidate_return_url:) }
  let(:candidate_return_url) { nil }
  let(:public_market) { create(:public_market, :completed, editor:, sync_status: 'sync_completed') }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before { sign_in_as_candidate(user, market_application) }

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
        expect(response.body).to include('Synchronisation')
      end
    end

    describe 'redirect URL' do
      before do
        market_application.update!(sync_status: :sync_completed, completed_at: Time.current)
        get sync_status_path
      end

      context 'when editor has candidate_return_url configured' do
        let(:candidate_return_url) { 'https://editor.example.com/callback' }

        it 'displays redirect link with both identifiers as query params' do
          expect(response.body).to include("market_identifier=#{public_market.identifier}")
          expect(response.body).to include("application_identifier=#{market_application.identifier}")
        end
      end

      context 'when editor has no candidate_return_url configured' do
        let(:candidate_return_url) { nil }

        it 'does not display a return link' do
          expect(response.body).not_to include(I18n.t('candidate.sync_status.return_to_editor', editor: editor.name))
        end
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

    context 'when the market_application belongs to a grouping member' do
      let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application) }

      before { get sync_status_path }

      it 'does not enter the polling loop (no sync-status controller wired)' do
        expect(response.body).not_to include('data-controller="sync-status"')
      end

      it 'shows the transmitted confirmation title' do
        expect(response.body).to include(I18n.t('candidate.sync_status.grouping_member_title'))
      end

      it 'does not offer an attestation download' do
        expect(response.body).not_to include(I18n.t('candidate.sync_status.download_attestation'))
      end
    end

    context 'when the market_application belongs to a co_traitant' do
      let(:market_application) do
        create(:market_application, :completed, public_market:, siret: '80245139600021', application_mode: :groupement)
      end
      let(:grouping) { create(:grouping, public_market:) }

      before do
        allow(SiretValidator).to receive(:valid?).and_return(true)
        create(:grouping_member, :co_traitant, grouping:, siret: market_application.siret, market_application:,
          status: :completed)
        get sync_status_path
      end

      it 'confirms the transmission to the mandataire' do
        expect(response.body).to include(I18n.t('candidate.sync_status.co_traitant_title'))
        expect(response.body).to include(I18n.t('candidate.sync_status.co_traitant_message'))
      end

      it 'links back to the grouping dashboard' do
        expect(response.body).to include(grouping_dashboard_candidate_market_application_path(market_application.identifier))
      end

      context 'when the co_traitant has not transmitted yet' do
        let(:market_application) do
          create(:market_application, public_market:, siret: '80245139600021', application_mode: :groupement)
        end

        it 'redirects to the grouping dashboard' do
          expect(response).to redirect_to(grouping_dashboard_candidate_market_application_path(market_application.identifier))
        end
      end

      it 'does not mention any attestation' do
        expect(response.body).not_to include(I18n.t('candidate.sync_status.download_attestation'))
        expect(response.body).not_to include('attestation')
      end
    end
  end
end

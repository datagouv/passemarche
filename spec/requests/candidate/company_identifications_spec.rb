# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::CompanyIdentifications', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before { sign_in_as_candidate(user, market_application) }

  describe 'GET /candidate/market_applications/:identifier/company_identification' do
    it 'returns ok' do
      get company_identification_candidate_market_application_path(market_application.identifier)

      expect(response).to have_http_status(:ok)
    end

    context 'when the application is completed' do
      let(:market_application) { create(:market_application, :completed, public_market:, siret: '73282932000074') }

      it 'redirects to sync status' do
        get company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(candidate_sync_status_path(market_application.identifier))
      end
    end

    context 'when the application does not exist' do
      it 'returns not found' do
        get company_identification_candidate_market_application_path('unknown-identifier')

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /candidate/market_applications/:identifier/company_identification' do
    context 'when the market has no lots' do
      it 'redirects to api_data_recovery_status wizard step' do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          step_candidate_market_application_path(market_application.identifier, :api_data_recovery_status)
        )
      end

      it 'enqueues FetchApiDataCoordinatorJob when api_fetch_status is empty' do
        market_application.update!(api_fetch_status: {})

        expect do
          patch company_identification_candidate_market_application_path(market_application.identifier)
        end.to have_enqueued_job(FetchApiDataCoordinatorJob).with(market_application.id)
      end

      it 'does not enqueue FetchApiDataCoordinatorJob when api_fetch_status is already present' do
        market_application.update!(api_fetch_status: { 'insee' => { 'status' => 'completed' } })

        expect do
          patch company_identification_candidate_market_application_path(market_application.identifier)
        end.not_to have_enqueued_job(FetchApiDataCoordinatorJob)
      end
    end

    context 'when the market has lots' do
      before { create(:lot, public_market:, name: 'Lot 1') }

      it 'redirects to lot selection' do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          lot_selection_candidate_market_application_path(market_application.identifier)
        )
      end
    end

    context 'when the application is completed' do
      let(:market_application) { create(:market_application, :completed, public_market:, siret: '73282932000074') }

      it 'redirects to sync status' do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(candidate_sync_status_path(market_application.identifier))
      end
    end
  end
end

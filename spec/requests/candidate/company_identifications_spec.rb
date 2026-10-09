# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::CompanyIdentifications', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)
    sign_in_as_candidate(user, market_application)
  end

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

    context 'when the groupement feature flag is enabled and no mode has been chosen yet' do
      before { allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true) }

      it 'redirects to the application mode choice screen instead of rendering the step' do
        get company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          application_mode_candidate_market_application_path(market_application.identifier)
        )
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

    context 'when the co_traitant belongs to a solidaire grouping' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) do
        create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :solidaire)
      end
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end
      let(:lot1) { create(:lot, public_market:) }
      let(:lot2) { create(:lot, public_market:) }

      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
        mandataire_application.lots << lot1 << lot2
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it 'skips the lot selection screen and redirects to api_data_recovery_status' do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          step_candidate_market_application_path(market_application.identifier, :api_data_recovery_status)
        )
      end

      it "assigns all the mandataire's lots to the co_traitant application" do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(market_application.reload.lots).to contain_exactly(lot1, lot2)
      end
    end

    context 'when the co_traitant belongs to a conjoint grouping' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) do
        create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :conjoint)
      end
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end

      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
        mandataire_application.lots << create(:lot, public_market:)
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it 'redirects to lot selection like a regular groupement member' do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          lot_selection_candidate_market_application_path(market_application.identifier)
        )
      end

      it 'does not pre-assign any lot' do
        patch company_identification_candidate_market_application_path(market_application.identifier)

        expect(market_application.reload.lots).to be_empty
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::LotSelections', type: :request do
  include ActiveJob::TestHelper

  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }
  let!(:lot) { create(:lot, public_market:, name: 'Lot 1') }

  before do
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)
    sign_in_as_candidate(user, market_application)
  end

  describe 'GET /candidate/market_applications/:identifier/lot_selection' do
    context 'when the groupement feature flag is enabled and no mode has been chosen yet' do
      before { allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true) }

      it 'redirects to the application mode choice screen instead of rendering the step' do
        get lot_selection_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          application_mode_candidate_market_application_path(market_application.identifier)
        )
      end
    end
  end

  describe 'PATCH /candidate/market_applications/:identifier/lot_selection' do
    it 'saves lot selection and redirects to preparation page' do
      patch lot_selection_candidate_market_application_path(market_application.identifier),
        params: { market_application: { lot_ids: [lot.id] } }

      expect(response).to redirect_to(
        lot_selection_candidate_market_application_path(market_application.identifier)
      )
      expect(market_application.reload.lot_ids).to include(lot.id)
    end

    it 'does not enqueue FetchApiDataCoordinatorJob' do
      expect do
        patch lot_selection_candidate_market_application_path(market_application.identifier),
          params: { market_application: { lot_ids: [lot.id] } }
      end.not_to have_enqueued_job(FetchApiDataCoordinatorJob)
    end
  end
end

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

    context 'when the market_application belongs to a co_traitant' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end
      let!(:other_lot) { create(:lot, public_market:, name: 'Lot hors périmètre') }

      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
        mandataire_application.lots << lot
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it 'only lists lots within the groupement scope' do
        get lot_selection_candidate_market_application_path(market_application.identifier)

        expect(response.body).to include(lot.name)
        expect(response.body).not_to include(other_lot.name)
      end

      it 'uses the co_traitant specific wording' do
        get lot_selection_candidate_market_application_path(market_application.identifier)

        expect(response.body).to include(I18n.t('candidate.lot_selection.co_traitant_title'))
        expect(response.body).to include(I18n.t('candidate.lot_selection.co_traitant_subtitle'))
      end
    end

    context 'when the market_application belongs to a co_traitant of a solidaire grouping' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) do
        create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :solidaire)
      end
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end

      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
        mandataire_application.lots << lot
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it "shows the recap with the mandataire's lots" do
        get lot_selection_candidate_market_application_path(market_application.identifier)

        expect(response.body).to include(I18n.t('candidate.lot_selection.lots_list_title'))
        expect(response.body).to include(lot.name)
      end

      it 'does not offer to edit the lots' do
        get lot_selection_candidate_market_application_path(market_application.identifier)

        expect(response.body).not_to include(I18n.t('candidate.lot_selection.edit_lots'))
      end

      it 'keeps the recap when the edit screen is requested' do
        get lot_selection_candidate_market_application_path(market_application.identifier, edit: 1)

        expect(response.body).not_to include('market_application[lot_ids][]')
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

    context 'when the market_application belongs to a co_traitant' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end
      let!(:other_lot) { create(:lot, public_market:, name: 'Lot hors périmètre') }

      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
        mandataire_application.lots << lot
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it 'accepts a lot within the groupement scope' do
        patch lot_selection_candidate_market_application_path(market_application.identifier),
          params: { market_application: { lot_ids: [lot.id] } }

        expect(market_application.reload.lot_ids).to contain_exactly(lot.id)
      end

      it 'redirects to the lot selection recap screen, like solo and mandataire applications' do
        patch lot_selection_candidate_market_application_path(market_application.identifier),
          params: { market_application: { lot_ids: [lot.id] } }

        expect(response).to redirect_to(
          lot_selection_candidate_market_application_path(market_application.identifier)
        )
      end

      it 'rejects a lot outside the groupement scope' do
        patch lot_selection_candidate_market_application_path(market_application.identifier),
          params: { market_application: { lot_ids: [other_lot.id] } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(market_application.reload.lot_ids).to be_empty
      end
    end

    context 'when the market_application belongs to a co_traitant of a solidaire grouping' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) do
        create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :solidaire)
      end
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end

      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
        mandataire_application.lots << lot
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it 'redirects to the recap without saving any lot' do
        patch lot_selection_candidate_market_application_path(market_application.identifier),
          params: { market_application: { lot_ids: [lot.id] } }

        expect(response).to redirect_to(lot_selection_candidate_market_application_path(market_application.identifier))
        expect(market_application.reload.lot_ids).to be_empty
      end
    end
  end
end

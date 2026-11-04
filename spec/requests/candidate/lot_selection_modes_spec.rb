# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::LotSelectionModes', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
  end

  describe 'GET .../lot_selection_mode' do
    it 'returns 404 when the feature flag is disabled' do
      allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)

      get lot_selection_mode_candidate_market_application_path(market_application.identifier)
      expect(response).to have_http_status(:not_found)
    end

    context 'when the market_application is not mandataire of any grouping (mode not chosen)' do
      it 'redirects to application_mode' do
        get lot_selection_mode_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(application_mode_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when the application mode is solo' do
      before { market_application.update!(application_mode: :solo) }

      it 'redirects to application_mode' do
        get lot_selection_mode_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(application_mode_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when the market_application is mandataire of a grouping' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
      end

      it 'redirects to grouping_legal_type when the public market has no lots' do
        get lot_selection_mode_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(grouping_legal_type_candidate_market_application_path(market_application.identifier))
      end

      context 'when the public market has lots' do
        before { create(:lot, public_market:) }

        it 'renders successfully' do
          get lot_selection_mode_candidate_market_application_path(market_application.identifier)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t('candidate.lot_selection_modes.title'))
        end
      end
    end
  end

  describe 'PATCH .../lot_selection_mode' do
    let(:lot1) { create(:lot, public_market:) }
    let(:lot2) { create(:lot, public_market:) }

    before do
      lot1
      lot2
      market_application.update!(application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
    end

    it 'assigns the selected lots and redirects to grouping_legal_type' do
      patch lot_selection_mode_candidate_market_application_path(market_application.identifier),
        params: { lot_modes: { lot1.id.to_s => 'groupement', lot2.id.to_s => 'none' } }

      expect(market_application.reload.lots).to contain_exactly(lot1)
      expect(response).to redirect_to(grouping_legal_type_candidate_market_application_path(market_application.identifier))
    end

    it 'rejects an incomplete selection with a 422' do
      patch lot_selection_mode_candidate_market_application_path(market_application.identifier),
        params: { lot_modes: { lot1.id.to_s => 'none', lot2.id.to_s => 'none' } }

      expect(response).to have_http_status(:unprocessable_content)
      rendered = Nokogiri::HTML(response.body)
      expect(rendered.text).to include(I18n.t('candidate.validations.lot_selection_mode_incomplete'))
    end
  end
end

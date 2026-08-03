# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::ApplicationModes', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
  end

  describe 'authentication' do
    it 'renders the login form instead of the page when not authenticated' do
      other_application = create(:market_application, public_market:, siret: '11122233300014')

      get application_mode_candidate_market_application_path(other_application.identifier)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('candidate.sessions.new.title'))
      expect(response.body).not_to include(I18n.t('candidate.application_modes.title'))
    end
  end

  describe 'GET /candidate/market_applications/:identifier/application_mode' do
    it 'renders successfully when the mode is not chosen yet' do
      get application_mode_candidate_market_application_path(market_application.identifier)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when the feature flag is disabled' do
      allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)

      get application_mode_candidate_market_application_path(market_application.identifier)
      expect(response).to have_http_status(:not_found)
    end

    it 'redirects to company_identification when the mode is already chosen' do
      market_application.update!(application_mode: :solo)

      get application_mode_candidate_market_application_path(market_application.identifier)
      expect(response).to redirect_to(
        company_identification_candidate_market_application_path(market_application.identifier)
      )
    end

    context 'when the mode is groupement and the legal type is not chosen yet' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
      end

      it 'redirects to grouping_legal_type instead of company_identification' do
        get application_mode_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          grouping_legal_type_candidate_market_application_path(market_application.identifier)
        )
      end
    end

    context 'when the mode is groupement and the legal type is already chosen' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
      end

      it 'redirects to company_identification' do
        get application_mode_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          company_identification_candidate_market_application_path(market_application.identifier)
        )
      end
    end

    context 'when the application is already completed' do
      let(:market_application) do
        create(:market_application, :completed, public_market:, siret: '73282932000074')
      end

      it 'redirects to sync status instead of showing the choice screen' do
        get application_mode_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(candidate_sync_status_path(market_application.identifier))
      end
    end
  end

  describe 'PATCH /candidate/market_applications/:identifier/application_mode' do
    it 'sets the mode to solo and redirects to company_identification' do
      patch application_mode_candidate_market_application_path(market_application.identifier),
        params: { application_mode: 'solo' }

      expect(market_application.reload).to be_solo
      expect(response).to redirect_to(
        company_identification_candidate_market_application_path(market_application.identifier)
      )
    end

    it 'creates a grouping when choosing groupement' do
      expect do
        patch application_mode_candidate_market_application_path(market_application.identifier),
          params: { application_mode: 'groupement' }
      end.to change(Grouping, :count).by(1)

      expect(market_application.reload).to be_groupement
      expect(response).to redirect_to(
        grouping_legal_type_candidate_market_application_path(market_application.identifier)
      )
    end

    it 'does not require re-authentication when reaching the next step after choosing groupement' do
      patch application_mode_candidate_market_application_path(market_application.identifier),
        params: { application_mode: 'groupement' }

      get company_identification_candidate_market_application_path(market_application.identifier)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t('candidate.sessions.new.siret_label'))
    end

    it 'creates two applications when choosing mixte and redirects to grouping_legal_type' do
      expect do
        patch application_mode_candidate_market_application_path(market_application.identifier),
          params: { application_mode: 'mixte' }
      end.to change(MarketApplication, :count).by(1)

      groupement_application = MarketApplication.find_by(public_market:, siret: market_application.siret,
        application_mode: :groupement)
      expect(response).to redirect_to(
        grouping_legal_type_candidate_market_application_path(groupement_application.identifier)
      )
    end

    it 'associates the authenticated user to the groupement counterpart created in mixte mode' do
      patch application_mode_candidate_market_application_path(market_application.identifier),
        params: { application_mode: 'mixte' }

      groupement_application = MarketApplication.where(public_market:, siret: market_application.siret,
        application_mode: :groupement).sole

      expect(groupement_application.user).to eq(user)
    end

    it 'does not require re-authentication when reaching the next step after choosing mixte' do
      patch application_mode_candidate_market_application_path(market_application.identifier),
        params: { application_mode: 'mixte' }

      groupement_application = MarketApplication.where(public_market:, siret: market_application.siret,
        application_mode: :groupement).sole

      get company_identification_candidate_market_application_path(groupement_application.identifier)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t('candidate.sessions.new.siret_label'))
    end

    context 'when the SIRET is already mandataire of a grouping on this market' do
      before do
        other_application = create(:market_application, public_market:, siret: market_application.siret,
          application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: other_application)
      end

      it 'rejects groupement mode with a 422' do
        patch application_mode_candidate_market_application_path(market_application.identifier),
          params: { application_mode: 'groupement' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(market_application.reload.application_mode).to be_nil
      end

      it 'renders the already-mandataire error message and re-disables groupement/mixte' do
        patch application_mode_candidate_market_application_path(market_application.identifier),
          params: { application_mode: 'groupement' }

        rendered = Nokogiri::HTML(response.body)
        expect(rendered.text).to include(I18n.t('candidate.validations.already_mandataire'))
        expect(rendered.text).to include(I18n.t('candidate.application_modes.already_mandataire_box.title'))

        expect(rendered.at_css('#application_mode_groupement')['disabled']).to eq('disabled')
        expect(rendered.at_css('#application_mode_mixte')['disabled']).to eq('disabled')
      end

      it 'still allows solo mode' do
        patch application_mode_candidate_market_application_path(market_application.identifier),
          params: { application_mode: 'solo' }

        expect(response).to redirect_to(
          company_identification_candidate_market_application_path(market_application.identifier)
        )
      end
    end
  end
end

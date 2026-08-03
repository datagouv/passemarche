# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingLegalTypes', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
  end

  describe 'GET /candidate/market_applications/:identifier/grouping_legal_type' do
    context 'when the market_application is mandataire of a grouping' do
      before { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil) }

      it 'renders successfully' do
        get grouping_legal_type_candidate_market_application_path(market_application.identifier)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.grouping_legal_types.title'))
      end

      it 'returns 404 when the feature flag is disabled' do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)

        get grouping_legal_type_candidate_market_application_path(market_application.identifier)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the market_application is not mandataire of any grouping' do
      it 'redirects to application_mode' do
        get grouping_legal_type_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          application_mode_candidate_market_application_path(market_application.identifier)
        )
      end
    end

    context 'when the application mode is solo' do
      let(:market_application) do
        create(:market_application, public_market:, siret: '73282932000074', application_mode: :solo)
      end

      it 'redirects to application_mode' do
        get grouping_legal_type_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(
          application_mode_candidate_market_application_path(market_application.identifier)
        )
      end
    end
  end

  describe 'PATCH /candidate/market_applications/:identifier/grouping_legal_type' do
    before { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil) }

    it 'sets the legal_type and redirects to company_identification' do
      patch grouping_legal_type_candidate_market_application_path(market_application.identifier),
        params: { legal_type: 'conjoint_mandataire_solidaire' }

      expect(Grouping.find_by(mandataire_market_application: market_application).legal_type)
        .to eq('conjoint_mandataire_solidaire')
      expect(response).to redirect_to(
        company_identification_candidate_market_application_path(market_application.identifier)
      )
    end

    it 'rejects an invalid legal_type with a 422' do
      patch grouping_legal_type_candidate_market_application_path(market_application.identifier),
        params: { legal_type: 'invalid_garbage' }

      expect(response).to have_http_status(:unprocessable_content)
      rendered = Nokogiri::HTML(response.body)
      expect(rendered.text).to include(I18n.t('candidate.validations.legal_type_invalid'))
    end
  end
end

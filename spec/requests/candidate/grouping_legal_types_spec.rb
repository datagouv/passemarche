# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingLegalTypes', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
  end

  def wizard_step_path(market_application, step)
    case step
    when :application_mode
      application_mode_candidate_market_application_path(market_application.identifier)
    when :grouping_legal_type
      grouping_legal_type_candidate_market_application_path(market_application.identifier)
    end
  end

  describe 'GET .../grouping_legal_type' do
    context 'when the market_application is mandataire of a grouping' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
      end

      it 'renders successfully' do
        get wizard_step_path(market_application, :grouping_legal_type)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.grouping_legal_types.title'))
      end
    end

    context 'when the market_application is not mandataire of any grouping (mode not chosen)' do
      it 'redirects to application_mode' do
        get wizard_step_path(market_application, :grouping_legal_type)

        expect(response).to redirect_to(wizard_step_path(market_application, :application_mode))
      end
    end

    context 'when the application mode is solo' do
      before { market_application.update!(application_mode: :solo) }

      it 'redirects to application_mode' do
        get wizard_step_path(market_application, :grouping_legal_type)

        expect(response).to redirect_to(wizard_step_path(market_application, :application_mode))
      end
    end
  end

  describe 'PATCH .../grouping_legal_type' do
    before do
      market_application.update!(application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
    end

    it 'sets the legal_type and redirects to company_identification' do
      patch wizard_step_path(market_application, :grouping_legal_type), params: { legal_type: 'conjoint_mandataire_solidaire' }

      expect(Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: market_application.id }).legal_type)
        .to eq('conjoint_mandataire_solidaire')
      expect(response).to redirect_to(
        company_identification_candidate_market_application_path(market_application.identifier)
      )
    end

    it 'rejects an invalid legal_type with a 422' do
      patch wizard_step_path(market_application, :grouping_legal_type), params: { legal_type: 'invalid_garbage' }

      expect(response).to have_http_status(:unprocessable_content)
      rendered = Nokogiri::HTML(response.body)
      expect(rendered.text).to include(I18n.t('candidate.validations.legal_type_invalid'))
    end
  end
end

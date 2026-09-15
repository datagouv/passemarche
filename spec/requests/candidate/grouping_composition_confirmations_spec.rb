# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingCompositionConfirmations', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
    market_application.update!(application_mode: :groupement)
  end

  let!(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
  end

  describe 'GET .../grouping_composition_confirmation' do
    it 'renders the summary' do
      create(:grouping_member, :co_traitant, grouping:)

      get grouping_composition_confirmation_candidate_market_application_path(market_application.identifier)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('candidate.grouping_compositions.confirm.title'))
    end

    it 'redirects back to grouping_composition when there is no co-traitant yet' do
      get grouping_composition_confirmation_candidate_market_application_path(market_application.identifier)

      expect(response).to redirect_to(grouping_composition_candidate_market_application_path(market_application.identifier))
    end
  end

  describe 'PATCH .../grouping_composition_confirmation' do
    context 'when the grouping has at least one co_traitant' do
      before { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

      it 'sends invitations and redirects to the dashboard with a success message' do
        patch grouping_composition_confirmation_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(candidate_dashboard_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('candidate.grouping_compositions.success'))
      end
    end

    context 'when the confirmation interactor fails' do
      before { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

      it 'renders the summary with an error' do
        allow(Candidate::ConfirmGroupingComposition).to receive(:call).and_return(
          OpenStruct.new(success?: false, errors: { grouping: [I18n.t('candidate.validations.no_co_traitant')] })
        )

        patch grouping_composition_confirmation_candidate_market_application_path(market_application.identifier)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t('candidate.validations.no_co_traitant'))
      end
    end
  end
end

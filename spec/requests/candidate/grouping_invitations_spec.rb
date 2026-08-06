# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingInvitations', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :conjoint)
  end

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe 'GET /candidate/grouping_invitations/:token' do
    context 'when the token matches an invited grouping member' do
      let(:grouping_member) do
        create(:grouping_member, :co_traitant, grouping:, invitation_token: 'valid-token-123',
          invitation_token_created_at: Time.current)
      end

      it 'returns a successful response' do
        get candidate_grouping_invitation_path(grouping_member.invitation_token)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the token does not match any grouping member' do
      it 'returns a 404' do
        get candidate_grouping_invitation_path('unknown-token')

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

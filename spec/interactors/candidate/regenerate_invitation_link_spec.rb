# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::RegenerateInvitationLink, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :conjoint)
  end

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    let(:grouping_member) do
      create(:grouping_member, :co_traitant, grouping:, invitation_token: 'old-token',
        invitation_token_created_at: 1.day.ago)
    end

    subject(:result) { described_class.call(grouping_member:, notify:) }

    context 'without notification' do
      let(:notify) { false }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'generates a new invitation token' do
        expect { result }.to change { grouping_member.reload.invitation_token }.from('old-token')
      end

      it 'refreshes invitation_token_created_at' do
        expect { result }.to change { grouping_member.reload.invitation_token_created_at }
      end

      it 'does not send an email' do
        expect { result }.not_to have_enqueued_mail(GroupingInvitationMailer, :invitation)
      end
    end

    context 'with notification' do
      let(:notify) { true }

      it 'sends an invitation email' do
        expect { result }.to have_enqueued_mail(GroupingInvitationMailer, :invitation)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::ConfirmGroupingComposition, type: :interactor do
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
    subject(:result) { described_class.call(grouping:) }

    context 'when the grouping has at least one co_traitant' do
      let!(:member1) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }
      let!(:member2) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'generates an invitation token for each co_traitant' do
        result
        expect(member1.reload.invitation_token).to be_present
        expect(member2.reload.invitation_token).to be_present
      end

      it 'marks each co_traitant as invited' do
        result
        expect(member1.reload.invitation_sent?).to be true
        expect(member2.reload.invitation_sent?).to be true
      end

      it 'sends an invitation email to each co_traitant' do
        expect { result }.to have_enqueued_mail(GroupingInvitationMailer, :invitation).twice
      end

      it 'does not affect the mandataire member' do
        mandataire_member = grouping.mandataire_grouping_member
        result
        expect(mandataire_member.reload.invitation_token).to be_nil
      end
    end

    context 'when a co_traitant has already been invited' do
      let!(:already_invited) do
        create(:grouping_member, :co_traitant, grouping:, invitation_token: 'existing-token',
          invitation_token_created_at: 1.day.ago)
      end
      let!(:new_member) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

      it 'does not resend an invitation to the already invited member' do
        expect { result }.to have_enqueued_mail(GroupingInvitationMailer, :invitation).once
      end

      it 'does not change the already invited token' do
        result
        expect(already_invited.reload.invitation_token).to eq('existing-token')
      end
    end

    context 'when the grouping has no co_traitant' do
      it 'fails' do
        expect(result).to be_failure
      end

      it 'sets an error' do
        expect(result.errors[:grouping]).to be_present
      end

      it 'does not send any email' do
        expect { result }.not_to have_enqueued_mail(GroupingInvitationMailer, :invitation)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::RemoveGroupingMember, type: :interactor do
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
    subject(:result) { described_class.call(grouping:, grouping_member_id:) }

    context 'when the member exists, belongs to the grouping and has not been invited yet' do
      let!(:member) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }
      let(:grouping_member_id) { member.id }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'destroys the member' do
        expect { result }.to change(GroupingMember, :count).by(-1)
      end
    end

    context 'when the member has already been invited' do
      let!(:member) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: Time.current) }
      let(:grouping_member_id) { member.id }

      it 'fails' do
        expect(result).to be_failure
      end

      it 'does not destroy the member' do
        expect { result }.not_to change(GroupingMember, :count)
      end
    end

    context 'when the member does not belong to the grouping' do
      let(:other_grouping) do
        other_application = create(:market_application, public_market:, siret: '80245139600027',
          application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: other_application, legal_type: :conjoint)
      end
      let!(:member) { create(:grouping_member, :co_traitant, grouping: other_grouping, invitation_token_created_at: nil) }
      let(:grouping_member_id) { member.id }

      before { grouping }

      it 'fails' do
        expect(result).to be_failure
      end

      it 'does not destroy the member' do
        expect { result }.not_to change(GroupingMember, :count)
      end
    end

    context 'when the member does not exist' do
      let(:grouping_member_id) { -1 }

      it 'fails' do
        expect(result).to be_failure
      end
    end
  end
end

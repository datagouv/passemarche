# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkGroupingAsSubmitted, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    subject(:result) { described_class.call(grouping:, submission_mode:) }

    context 'when submission_mode is full and every member is completed' do
      let(:submission_mode) { :full }
      let(:grouping) { create(:grouping, public_market:) }

      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: Time.current)
      end

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'sets submitted_at and submission_mode' do
        expect { result }
          .to change { grouping.reload.submitted_at }.from(nil)
          .and change { grouping.reload.submission_mode }.from(nil).to('full')
      end
    end

    context 'when submission_mode is full but not every member is completed' do
      let(:submission_mode) { :full }
      let(:grouping) { create(:grouping, public_market:) }

      before { create(:grouping_member, :co_traitant, grouping:, status: :in_progress, invitation_token_created_at: Time.current) }

      it 'fails' do
        expect(result).to be_failure
      end

      it 'does not submit the grouping' do
        expect { result }.not_to(change { grouping.reload.submitted_at })
      end
    end

    context 'when submission_mode is full but the composition is not confirmed yet' do
      let(:submission_mode) { :full }
      let(:grouping) { create(:grouping, public_market:) }

      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: nil)
      end

      it 'fails' do
        expect(result).to be_failure
      end

      it 'does not submit the grouping' do
        expect { result }.not_to(change { grouping.reload.submitted_at })
      end
    end

    context 'when submission_mode is partial and at least one member has started' do
      let(:submission_mode) { :partial }
      let(:grouping) { create(:grouping, public_market:) }

      before { create(:grouping_member, :co_traitant, grouping:, status: :in_progress, invitation_token_created_at: Time.current) }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'sets submitted_at and submission_mode' do
        expect { result }
          .to change { grouping.reload.submitted_at }.from(nil)
          .and change { grouping.reload.submission_mode }.from(nil).to('partial')
      end
    end

    context 'when submission_mode is partial but no member has started' do
      let(:submission_mode) { :partial }
      let(:grouping) { create(:grouping, public_market:) }

      before { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: Time.current) }

      it 'fails' do
        expect(result).to be_failure
      end
    end

    context 'when submission_mode is partial but every member is already completed' do
      let(:submission_mode) { :partial }
      let(:grouping) { create(:grouping, public_market:) }

      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: Time.current)
      end

      it 'fails' do
        expect(result).to be_failure
      end
    end

    context 'when submission_mode is partial but the composition is not confirmed yet' do
      let(:submission_mode) { :partial }
      let(:grouping) { create(:grouping, public_market:) }

      before { create(:grouping_member, :co_traitant, grouping:, status: :in_progress, invitation_token_created_at: nil) }

      it 'fails' do
        expect(result).to be_failure
      end
    end

    context 'when the grouping is already submitted' do
      let(:submission_mode) { :full }
      let(:grouping) { create(:grouping, public_market:, submitted_at: 1.hour.ago) }

      it 'fails' do
        expect(result).to be_failure
      end

      it 'provides an error message' do
        expect(result.message).to eq('Groupement déjà soumis')
      end
    end

    context 'when the grouping gets submitted concurrently while acquiring the lock' do
      let(:submission_mode) { :full }
      let(:grouping) { create(:grouping, public_market:) }

      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: Time.current)

        allow(grouping).to receive(:with_lock).and_wrap_original do |original, &block|
          Grouping.find(grouping.id).submit!(mode: :full)
          original.call(&block)
        end
      end

      it 'fails instead of raising' do
        expect { result }.not_to raise_error
        expect(result).to be_failure
      end

      it 'provides an error message' do
        expect(result.message).to eq('Groupement déjà soumis')
      end
    end

    context 'when submission_mode is missing' do
      let(:submission_mode) { nil }
      let(:grouping) { create(:grouping, public_market:) }

      it 'fails instead of raising' do
        expect { result }.not_to raise_error
        expect(result).to be_failure
      end

      it 'provides an error message' do
        expect(result.message).to eq('Mode de soumission invalide')
      end
    end

    context 'when submission_mode is an unknown value' do
      let(:submission_mode) { 'bogus' }
      let(:grouping) { create(:grouping, public_market:) }

      it 'fails instead of raising' do
        expect { result }.not_to raise_error
        expect(result).to be_failure
      end
    end

    context 'when the public market deadline has passed' do
      let(:public_market) { create(:public_market, :completed, editor:, deadline: 1.day.ago) }
      let(:submission_mode) { :full }
      let(:grouping) { create(:grouping, public_market:) }

      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: Time.current)
      end

      it 'fails' do
        expect(result).to be_failure
      end
    end
  end
end

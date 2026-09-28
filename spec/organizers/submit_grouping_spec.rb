# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitGrouping, type: :organizer do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:grouping) { create(:grouping, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    grouping.mandataire_grouping_member.update!(status: :completed)
    create(:grouping_member, :co_traitant, grouping:, status: :completed, invitation_token_created_at: Time.current)
  end

  describe '.call' do
    subject(:result) { described_class.call(grouping:, submission_mode: :full) }

    it 'succeeds' do
      expect(result).to be_success
    end

    it 'submits the grouping' do
      expect { result }.to change { grouping.reload.submitted? }.from(false).to(true)
    end

    it 'queues the submission webhook' do
      expect { result }.to have_enqueued_job(GroupingSubmissionWebhookJob).with(grouping.id)
    end

    context 'when the grouping is not submittable for the given mode' do
      subject(:result) { described_class.call(grouping:, submission_mode: :partial) }

      it 'fails' do
        expect(result).to be_failure
      end

      it 'does not submit the grouping' do
        expect { result }.not_to(change { grouping.reload.submitted? })
      end
    end
  end
end

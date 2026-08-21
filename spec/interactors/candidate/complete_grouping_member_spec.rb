# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::CompleteGroupingMember, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    subject(:result) { described_class.call(market_application:) }

    context 'when the application belongs to a grouping member and is not completed yet' do
      let(:grouping) { create(:grouping, public_market:) }
      let(:market_application) { grouping.mandataire_market_application }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'marks the market_application as completed' do
        expect { result }.to change { market_application.reload.completed? }.from(false).to(true)
      end

      it 'marks the grouping_member as completed' do
        expect { result }.to change { grouping.mandataire_grouping_member.reload.status_completed? }.from(false).to(true)
      end

      it 'does not generate any attestation, PDF or webhook' do
        expect(GenerateAttestationPdf).not_to receive(:call)
        expect(QueueMarketApplicationWebhook).not_to receive(:call)

        result
      end
    end

    context 'when the application is not linked to any grouping member (solo)' do
      let(:market_application) { create(:market_application, public_market:, application_mode: :solo) }

      it 'succeeds and only marks the application as completed' do
        expect(result).to be_success
        expect(market_application.reload).to be_completed
      end
    end

    context 'when the application is already completed' do
      let(:grouping) { create(:grouping, public_market:) }
      let(:market_application) { grouping.mandataire_market_application }

      before { market_application.complete! }

      it 'fails' do
        expect(result).to be_failure
      end
    end
  end
end

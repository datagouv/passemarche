# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::SetUpGroupingMemberApplication, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:grouping) { create(:grouping, public_market:) }
  let(:grouping_member) do
    create(:grouping_member, :co_traitant, grouping:, siret: '13002526500013')
  end

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '.call' do
    context 'when the member has no market application yet' do
      it 'creates a market application for the member siret and public market' do
        result = described_class.call(grouping_member:)

        expect(result).to be_success
        expect(result.market_application.siret).to eq(grouping_member.siret)
        expect(result.market_application.public_market).to eq(public_market)
      end

      it 'links the created market application to the grouping member' do
        described_class.call(grouping_member:)

        expect(grouping_member.reload.market_application).to be_present
      end

      it 'is idempotent when called twice for the same member' do
        described_class.call(grouping_member:)

        expect do
          described_class.call(grouping_member:)
        end.not_to change(MarketApplication, :count)
      end
    end

    context 'when the member already has a market application' do
      let(:existing_application) { create(:market_application, public_market:, siret: grouping_member.siret, application_mode: :groupement) }

      before { grouping_member.update!(market_application: existing_application) }

      it 'reuses the existing market application without creating a new one' do
        expect do
          result = described_class.call(grouping_member:)
          expect(result.market_application).to eq(existing_application)
        end.not_to change(MarketApplication, :count)
      end
    end

    context 'when the siret already has an unrelated market application on the same public market' do
      let!(:unrelated_application) do
        create(:market_application, :completed, public_market:, siret: grouping_member.siret, application_mode: :groupement)
      end

      it 'creates a new market application instead of reusing the unrelated one' do
        expect do
          result = described_class.call(grouping_member:)
          expect(result.market_application).not_to eq(unrelated_application)
        end.to change(MarketApplication, :count).by(1)
      end

      it 'does not alter the unrelated application state' do
        described_class.call(grouping_member:)

        expect(unrelated_application.reload).to be_completed
      end

      it 'links the new market application to the grouping member' do
        described_class.call(grouping_member:)

        expect(grouping_member.reload.market_application).not_to eq(unrelated_application)
      end
    end
  end
end

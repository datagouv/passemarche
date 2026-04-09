# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LotSelectionPolicy do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:, lot_limit: nil) }
  let(:market_application) { create(:market_application, public_market:) }
  let(:lot1) { create(:lot, public_market:) }
  let(:lot2) { create(:lot, public_market:) }
  let(:lot3) { create(:lot, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '#valid?' do
    context 'when no lots are selected' do
      it 'is invalid' do
        policy = described_class.new(market_application, [])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.no_lot_selected'))
      end

      it 'is invalid when lot_ids contains only blank values' do
        policy = described_class.new(market_application, ['', nil, '0'])

        expect(policy.valid?).to be(false)
      end
    end

    context 'when lots are selected and there is no lot_limit' do
      it 'is valid with one lot' do
        policy = described_class.new(market_application, [lot1.id])

        expect(policy.valid?).to be(true)
      end

      it 'is valid with multiple lots' do
        policy = described_class.new(market_application, [lot1.id, lot2.id, lot3.id])

        expect(policy.valid?).to be(true)
      end
    end

    context 'when lot_limit is set' do
      before { public_market.update!(lot_limit: 2) }

      it 'is valid when selected lots count equals the limit' do
        policy = described_class.new(market_application, [lot1.id, lot2.id])

        expect(policy.valid?).to be(true)
      end

      it 'is valid when selected lots count is below the limit' do
        policy = described_class.new(market_application, [lot1.id])

        expect(policy.valid?).to be(true)
      end

      it 'is invalid when selected lots count exceeds the limit' do
        policy = described_class.new(market_application, [lot1.id, lot2.id, lot3.id])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_limit_exceeded', limit: 2, count: 3)
        )
      end
    end
  end
end

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

    context 'when the same lot is selected twice' do
      it 'is valid and keeps the lot once' do
        policy = described_class.new(market_application, [lot1.id, lot1.id.to_s])

        expect(policy.valid?).to be(true)
        expect(policy.lot_ids).to eq([lot1.id])
      end
    end

    context 'when a value is not a lot identifier' do
      it 'is invalid' do
        policy = described_class.new(market_application, ['abc', lot1.id])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.invalid_lot_id')
        )
      end

      it 'is invalid with a decimal number' do
        policy = described_class.new(market_application, [1.5, lot1.id])

        expect(policy.valid?).to be(false)
      end

      it 'is invalid with a boolean or a null mixed with valid lots' do
        [true, false, nil].each do |value|
          policy = described_class.new(market_application, [lot1.id, value])

          expect(policy.valid?).to be(false)
          expect(policy.errors[:base]).to include(
            I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.invalid_lot_id')
          )
        end
      end

      it 'rejects a zero identifier as an unknown lot' do
        policy = described_class.new(market_application, [lot1.id, 0])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_outside_market')
        )
      end
    end

    context 'when the form sends the empty value of the checkboxes' do
      it 'ignores it' do
        policy = described_class.new(market_application, ['', lot1.id.to_s])

        expect(policy.valid?).to be(true)
        expect(policy.lot_ids).to eq([lot1.id])
      end
    end

    context 'when a selected lot does not belong to the market' do
      let(:other_market_lot) { create(:lot, public_market: create(:public_market, :completed, editor:)) }

      it 'is invalid' do
        policy = described_class.new(market_application, [lot1.id, other_market_lot.id])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_outside_market')
        )
      end

      it 'is invalid when the lot does not exist' do
        policy = described_class.new(market_application, [lot1.id, 999_999_999])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_outside_market')
        )
      end
    end

    context 'when the market_application belongs to a co_traitant' do
      let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139601003', application_mode: :groupement)
      end

      before do
        mandataire_application.lots << lot1 << lot2
        create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      end

      it 'is valid when selected lots are within the groupement scope' do
        policy = described_class.new(market_application, [lot1.id])

        expect(policy.valid?).to be(true)
      end

      it 'is invalid when a selected lot is outside the groupement scope' do
        policy = described_class.new(market_application, [lot1.id, lot3.id])

        expect(policy.valid?).to be(false)
        expect(policy.errors[:base]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_outside_groupement_scope')
        )
      end
    end

    context 'when lot_limit is set and the feature flag is enabled' do
      before do
        lot1
        lot2
        lot3
        public_market.update!(lot_limit: 2)
        allow(FeatureFlags::LotLimit).to receive(:enabled?).and_return(true)
      end

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

    context 'when lot_limit is set but the feature flag is disabled' do
      before do
        lot1
        lot2
        lot3
        public_market.update!(lot_limit: 2)
        allow(FeatureFlags::LotLimit).to receive(:enabled?).and_return(false)
      end

      it 'is valid even when selected lots count exceeds the limit' do
        policy = described_class.new(market_application, [lot1.id, lot2.id, lot3.id])

        expect(policy.valid?).to be(true)
      end
    end
  end
end

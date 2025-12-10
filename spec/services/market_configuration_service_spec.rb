# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketConfigurationService do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, editor:, market_type_codes: ['supplies']) }
  let!(:supplies_market_type) { create(:market_type, code: 'supplies') }
  let!(:defense_market_type) { create(:market_type, code: 'defense') }
  let!(:mandatory_attribute) do
    create(:market_attribute, :mandatory, key: 'mandatory_field', category_key: 'test_category')
  end
  let!(:optional_attribute) do
    create(:market_attribute, key: 'optional_field', mandatory: false, category_key: 'test_category')
  end

  before do
    supplies_market_type.market_attributes << [mandatory_attribute, optional_attribute]
    defense_market_type.market_attributes << [mandatory_attribute]
  end

  describe '.call' do
    context 'with setup step' do
      it 'returns the public market when no params provided' do
        result = described_class.call(public_market, :setup, {})

        expect(result).to eq(public_market)
        expect(public_market.market_type_codes).to eq(['supplies'])
      end

      it 'returns the public market when add_defense_market_type is false' do
        params = { add_defense_market_type: 'false' }
        result = described_class.call(public_market, :setup, params)

        expect(result).to eq(public_market)
        expect(public_market.market_type_codes).to eq(['supplies'])
      end

      it 'adds defense market type when requested' do
        params = { add_defense_market_type: 'true' }
        result = described_class.call(public_market, :setup, params)

        expect(result).to eq(public_market)
        expect(public_market.reload.market_type_codes).to include('defense')
      end

      it 'does not duplicate defense market type if already present' do
        public_market.update!(market_type_codes: %w[supplies defense])
        params = { add_defense_market_type: 'true' }

        result = described_class.call(public_market, :setup, params)

        expect(result).to eq(public_market)
        expect(public_market.reload.market_type_codes.count('defense')).to eq(1)
      end

      it 'snapshots mandatory fields during setup' do
        described_class.call(public_market, :setup, {})

        expect(public_market.reload.market_attributes).to include(mandatory_attribute)
      end
    end

    context 'with category step' do
      before do
        public_market.market_attributes = [mandatory_attribute]
      end

      it 'adds selected optional attributes from the category' do
        params = { selected_attribute_keys: [optional_attribute.key] }
        result = described_class.call(public_market, :test_category, params)

        expect(result).to eq(public_market)
        expect(public_market.reload.market_attributes).to include(mandatory_attribute, optional_attribute)
      end

      it 'preserves existing mandatory attributes' do
        params = { selected_attribute_keys: [] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes).to include(mandatory_attribute)
      end

      it 'handles empty selected attributes' do
        params = { selected_attribute_keys: [] }

        expect do
          described_class.call(public_market, :test_category, params)
        end.not_to raise_error

        expect(public_market.reload.market_attributes).to eq([mandatory_attribute])
      end

      it 'only adds attributes from the current category' do
        other_category_attr = create(:market_attribute, key: 'other_field', mandatory: false, category_key: 'other')
        supplies_market_type.market_attributes << other_category_attr

        params = { selected_attribute_keys: [optional_attribute.key, other_category_attr.key] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes).to include(optional_attribute)
        expect(public_market.reload.market_attributes).not_to include(other_category_attr)
      end

      it 'does not duplicate attributes when adding again' do
        public_market.market_attributes << optional_attribute

        params = { selected_attribute_keys: [optional_attribute.key] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes.count { |a| a.key == optional_attribute.key }).to eq(1)
      end

      it 'removes previously selected optional attributes when deselected' do
        public_market.market_attributes << optional_attribute

        params = { selected_attribute_keys: [] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes).to include(mandatory_attribute)
        expect(public_market.reload.market_attributes).not_to include(optional_attribute)
      end

      it 'removes only deselected attributes while keeping newly selected ones' do
        other_optional = create(:market_attribute, key: 'other_optional', mandatory: false, category_key: 'test_category')
        supplies_market_type.market_attributes << other_optional
        public_market.market_attributes << optional_attribute

        params = { selected_attribute_keys: [other_optional.key] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes).to include(mandatory_attribute, other_optional)
        expect(public_market.reload.market_attributes).not_to include(optional_attribute)
      end

      it 'does not affect optional attributes from other categories when deselecting' do
        other_category_attr = create(:market_attribute, key: 'other_cat_field', mandatory: false, category_key: 'other')
        supplies_market_type.market_attributes << other_category_attr
        public_market.market_attributes << [optional_attribute, other_category_attr]

        params = { selected_attribute_keys: [] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes).to include(mandatory_attribute, other_category_attr)
        expect(public_market.reload.market_attributes).not_to include(optional_attribute)
      end
    end

    context 'with summary step' do
      it 'completes the market' do
        expect(public_market.completed?).to be false

        result = described_class.call(public_market, :summary, {})

        expect(result).to eq(public_market)
        expect(public_market.reload.completed?).to be true
      end

      it 'enqueues webhook sync job' do
        expect do
          described_class.call(public_market, :summary, {})
        end.to have_enqueued_job(PublicMarketWebhookJob).with(public_market.id)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketConfigurationService do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, editor:, market_type_codes: ['supplies']) }
  let!(:supplies_market_type) { create(:market_type, code: 'supplies') }
  let!(:defense_market_type) { create(:market_type, code: 'defense') }
  let!(:required_attribute) do
    create(:market_attribute, :required, key: 'required_field', category_key: 'test_category')
  end
  let!(:optional_attribute) do
    create(:market_attribute, key: 'optional_field', required: false, category_key: 'test_category')
  end

  before do
    supplies_market_type.market_attributes << [required_attribute, optional_attribute]
    defense_market_type.market_attributes << [required_attribute]
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

      it 'snapshots required fields during setup' do
        described_class.call(public_market, :setup, {})

        expect(public_market.reload.market_attributes).to include(required_attribute)
      end
    end

    context 'with category step' do
      before do
        # Setup has already been run, so required attributes should be present
        public_market.market_attributes = [required_attribute]
      end

      it 'adds selected optional attributes from the category' do
        params = { selected_attribute_keys: [optional_attribute.key] }
        result = described_class.call(public_market, :test_category, params)

        expect(result).to eq(public_market)
        expect(public_market.reload.market_attributes).to include(required_attribute, optional_attribute)
      end

      it 'preserves existing required attributes' do
        params = { selected_attribute_keys: [] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes).to include(required_attribute)
      end

      it 'handles empty selected attributes' do
        params = { selected_attribute_keys: [] }

        expect do
          described_class.call(public_market, :test_category, params)
        end.not_to raise_error

        expect(public_market.reload.market_attributes).to eq([required_attribute])
      end

      it 'only adds attributes from the current category' do
        other_category_attr = create(:market_attribute, key: 'other_field', required: false, category_key: 'other')
        supplies_market_type.market_attributes << other_category_attr

        params = { selected_attribute_keys: [optional_attribute.key, other_category_attr.key] }
        described_class.call(public_market, :test_category, params)

        # Should only add the attribute from test_category, not other
        expect(public_market.reload.market_attributes).to include(optional_attribute)
        expect(public_market.reload.market_attributes).not_to include(other_category_attr)
      end

      it 'does not duplicate attributes when adding again' do
        public_market.market_attributes << optional_attribute

        params = { selected_attribute_keys: [optional_attribute.key] }
        described_class.call(public_market, :test_category, params)

        expect(public_market.reload.market_attributes.count { |a| a.key == optional_attribute.key }).to eq(1)
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

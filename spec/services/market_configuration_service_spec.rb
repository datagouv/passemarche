# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketConfigurationService do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, editor: editor, market_type_codes: ['supplies']) }
  let!(:supplies_market_type) { create(:market_type, code: 'supplies') }
  let!(:defense_market_type) { create(:market_type, code: 'defense') }
  let!(:required_attribute) { create(:market_attribute, :required, key: 'required_field') }
  let!(:optional_attribute) { create(:market_attribute, key: 'optional_field', required: false) }

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
    end

    context 'with required_fields step' do
      it 'assigns required market attributes and returns next step' do
        result = described_class.call(public_market, :required_fields, {})

        expect(result).to be_a(Hash)
        expect(result[:public_market]).to eq(public_market)
        expect(result[:next_step]).to eq(:additional_fields)
        expect(public_market.reload.market_attributes).to include(required_attribute)
      end

      it 'preserves existing optional attributes when revisiting step' do
        # First, simulate user going through additional_fields step
        public_market.market_attributes = [required_attribute, optional_attribute]
        public_market.save!

        # Then simulate user going back to required_fields step
        result = described_class.call(public_market, :required_fields, {})

        expect(result).to be_a(Hash)
        expect(result[:next_step]).to eq(:additional_fields)
        # Should preserve both required and optional attributes
        expect(public_market.reload.market_attributes).to include(required_attribute, optional_attribute)
      end
    end

    context 'with additional_fields step' do
      before do
        public_market.market_attributes = [required_attribute]
      end

      it 'adds selected optional attributes and returns next step' do
        params = { selected_attribute_keys: [optional_attribute.key] }
        result = described_class.call(public_market, :additional_fields, params)

        expect(result).to be_a(Hash)
        expect(result[:public_market]).to eq(public_market)
        expect(result[:next_step]).to eq(:summary)
        expect(public_market.reload.market_attributes).to include(required_attribute, optional_attribute)
      end

      it 'preserves existing required attributes' do
        params = { selected_attribute_keys: [] }
        described_class.call(public_market, :additional_fields, params)

        expect(public_market.reload.market_attributes).to include(required_attribute)
      end

      it 'handles empty selected attributes' do
        params = { selected_attribute_keys: [] }

        expect {
          described_class.call(public_market, :additional_fields, params)
        }.not_to raise_error

        expect(public_market.reload.market_attributes).to eq([required_attribute])
      end
    end

    context 'with summary step' do
      it 'completes the market' do
        expect(public_market.completed?).to be false

        result = described_class.call(public_market, :summary, {})

        expect(result).to eq(public_market)
        expect(public_market.reload.completed?).to be true
      end
    end

    context 'with unknown step' do
      it 'raises ArgumentError' do
        expect {
          described_class.call(public_market, :unknown_step, {})
        }.to raise_error(ArgumentError, 'Unknown step: unknown_step')
      end
    end
  end
end

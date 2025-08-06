# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarketCreationService do
  let(:editor) { create(:editor) }
  let(:valid_params) do
    {
      name: 'Test Market',
      lot_name: 'Lot A',
      deadline: 1.month.from_now,
      market_type_codes: ['supplies']
    }
  end

  before do
    MarketType.find_or_create_by(code: 'supplies')
  end

  describe '.call' do
    context 'with valid parameters' do
      it 'creates a public market' do
        expect {
          described_class.call(editor, valid_params)
        }.to change(PublicMarket, :count).by(1)
      end

      it 'returns the created public market' do
        public_market = described_class.call(editor, valid_params)

        expect(public_market).to be_a(PublicMarket)
        expect(public_market.name).to eq('Test Market')
        expect(public_market.lot_name).to eq('Lot A')
        expect(public_market.editor).to eq(editor)
      end

      it 'assigns the market to the editor' do
        public_market = described_class.call(editor, valid_params)

        expect(public_market.editor).to eq(editor)
        expect(editor.public_markets).to include(public_market)
      end
    end

    context 'with nil editor' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.call(nil, valid_params)
        }.to raise_error(ActiveRecord::RecordNotFound, 'Editor not found')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { valid_params.merge(name: nil) }

      it 'raises ActiveRecord::RecordInvalid' do
        expect {
          described_class.call(editor, invalid_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'parameter filtering' do
      let(:params_with_extra_data) do
        valid_params.merge(
          unauthorized_field: 'should be filtered',
          another_field: 'also filtered'
        )
      end

      it 'only uses allowed parameters' do
        public_market = described_class.call(editor, params_with_extra_data)

        expect(public_market.name).to eq('Test Market')
        expect(public_market).not_to respond_to(:unauthorized_field)
      end
    end
  end
end

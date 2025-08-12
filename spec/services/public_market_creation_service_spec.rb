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

  describe 'service object pattern' do
    describe '#perform' do
      context 'with valid parameters' do
        let(:service) { described_class.new(editor, valid_params).perform }

        it 'returns success' do
          expect(service.success?).to be true
          expect(service.failure?).to be false
        end

        it 'has no errors' do
          expect(service.errors).to be_blank
        end

        it 'creates a public market' do
          expect { service }.to change(PublicMarket, :count).by(1)
        end

        it 'returns the created market as result' do
          expect(service.result).to be_a(PublicMarket)
          expect(service.result.name).to eq('Test Market')
          expect(service.result.editor).to eq(editor)
        end
      end

      context 'with nil editor' do
        let(:service) { described_class.new(nil, valid_params).perform }

        it 'returns failure' do
          expect(service.success?).to be false
          expect(service.failure?).to be true
        end

        it 'has editor error' do
          expect(service.errors[:editor]).to include('Editor not found')
        end

        it 'has no result' do
          expect(service.result).to be_nil
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) { valid_params.merge(name: nil) }
        let(:service) { described_class.new(editor, invalid_params).perform }

        it 'returns failure' do
          expect(service.success?).to be false
          expect(service.failure?).to be true
        end

        it 'has validation errors' do
          expect(service.errors[:name]).to be_present
        end

        it 'has no result' do
          expect(service.result).to be_nil
        end
      end
    end
  end
end

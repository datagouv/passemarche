# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lot, type: :model do
  let(:public_market) { create(:public_market, :completed) }
  describe 'effective_market_type' do
    it 'returns the buyer type when set' do
      platform_type = create(:market_type)
      buyer_type = create(:market_type, :services)
      lot = create(:lot, public_market:, platform_market_type: platform_type, market_type: buyer_type)
      expect(lot.effective_market_type).to eq(buyer_type)
    end

    it 'returns the platform type when no buyer override' do
      platform_type = create(:market_type)
      lot = create(:lot, public_market:, platform_market_type: platform_type, market_type: nil)
      expect(lot.effective_market_type).to eq(platform_type)
    end

    it 'returns nil when neither type is set' do
      lot = create(:lot, public_market:, platform_market_type: nil)
      expect(lot.effective_market_type).to be_nil
    end
  end

  describe 'validations' do
    it 'requires name to be present' do
      lot = build(:lot, public_market:, name: nil)
      expect(lot).not_to be_valid
      expect(lot.errors[:name]).to be_present
    end

    it 'requires public_market to be present' do
      lot = build(:lot, public_market: nil)
      expect(lot).not_to be_valid
      expect(lot.errors[:public_market]).to be_present
    end

    describe 'cpv_code format' do
      it 'accepts a blank cpv_code' do
        lot = build(:lot, public_market:, cpv_code: nil)
        expect(lot).to be_valid
      end

      it 'accepts a valid cpv_code' do
        lot = build(:lot, public_market:, cpv_code: '45000000-3')
        expect(lot).to be_valid
      end

      it 'rejects a cpv_code without check digit' do
        lot = build(:lot, public_market:, cpv_code: '45000000')
        expect(lot).not_to be_valid
        expect(lot.errors[:cpv_code]).to be_present
      end

      it 'rejects a cpv_code with letters' do
        lot = build(:lot, public_market:, cpv_code: 'AB000000-3')
        expect(lot).not_to be_valid
        expect(lot.errors[:cpv_code]).to be_present
      end

      it 'rejects a cpv_code that is too short' do
        lot = build(:lot, public_market:, cpv_code: '4500000-3')
        expect(lot).not_to be_valid
        expect(lot.errors[:cpv_code]).to be_present
      end

      it 'rejects a cpv_code with multiple check digits' do
        lot = build(:lot, public_market:, cpv_code: '45000000-33')
        expect(lot).not_to be_valid
        expect(lot.errors[:cpv_code]).to be_present
      end
    end
  end

  describe 'position' do
    it 'auto-assigns position on create' do
      lot = create(:lot, public_market:, position: nil)
      expect(lot.position).to be_present
    end

    it 'assigns position scoped to public_market' do
      other_market = create(:public_market, :completed)
      create(:lot, public_market: other_market)

      lot1 = create(:lot, public_market:)
      lot2 = create(:lot, public_market:)

      expect(lot1.position).to eq(1)
      expect(lot2.position).to eq(2)
    end

    it 'does not override an explicit position' do
      lot = create(:lot, public_market:, position: 5)
      expect(lot.position).to eq(5)
    end
  end

  describe 'scopes' do
    it 'orders lots by position' do
      lot_b = create(:lot, public_market:, position: 2)
      lot_a = create(:lot, public_market:, position: 1)

      expect(described_class.ordered.to_a).to eq([lot_a, lot_b])
    end
  end
end

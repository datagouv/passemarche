# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lot, type: :model do
  let(:public_market) { create(:public_market, :completed) }

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

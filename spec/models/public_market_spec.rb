# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarket, type: :model do
  describe 'associations' do
    it { should belong_to(:editor) }
  end

  describe 'identifier generation' do
    let(:editor) { create(:editor) }
    let(:public_market) { build(:public_market, editor: editor, identifier: nil) }

    it 'generates an identifier before validation on create' do
      expect(public_market.identifier).to be_nil
      public_market.valid?
      expect(public_market.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end
  end

  describe '#completed?' do
    it 'returns false when completed_at is nil' do
      market = build(:public_market, completed_at: nil)
      expect(market.completed?).to be false
    end

    it 'returns true when completed_at is present' do
      market = build(:public_market, completed_at: Time.current)
      expect(market.completed?).to be true
    end
  end

  describe '#complete!' do
    let(:public_market) { create(:public_market, completed_at: nil) }

    it 'sets completed_at to current time' do
      time_before = Time.current
      public_market.complete!
      time_after = Time.current

      expect(public_market.completed_at).to be_between(time_before, time_after)
    end

    it 'persists the change' do
      public_market.complete!
      public_market.reload
      expect(public_market.completed_at).to be_present
    end
  end
end

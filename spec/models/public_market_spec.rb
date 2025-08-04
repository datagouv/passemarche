# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarket, type: :model do
  describe 'associations' do
    it { should belong_to(:editor) }
    it { should have_and_belong_to_many(:market_types) }
    it { should have_and_belong_to_many(:market_attributes) }
  end

  describe 'validations' do
    let(:editor) { create(:editor) }

    describe 'identifier validation' do
      it 'validates presence of identifier' do
        public_market = build(:public_market, editor: editor, identifier: nil)
        public_market.valid?
        expect(public_market.identifier).to be_present
      end

      it 'validates uniqueness of identifier' do
        existing_market = create(:public_market, editor: editor)
        duplicate_market = build(:public_market, editor: editor, identifier: existing_market.identifier)
        expect(duplicate_market).not_to be_valid
        expect(duplicate_market.errors[:identifier]).to be_present
      end
    end

    it { should validate_presence_of(:market_name) }
    it { should validate_presence_of(:deadline) }
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

  describe '#complete!' do
    let(:public_market) { create(:public_market, completed_at: nil) }

    it 'sets completed_at to current time' do
      time_before = Time.zone.now
      public_market.complete!
      time_after = Time.zone.now

      expect(public_market.completed_at).to be_between(time_before, time_after)
    end

    it 'persists the change' do
      public_market.complete!
      public_market.reload
      expect(public_market.completed_at).to be_present
    end
  end

  describe 'selected_optional_fields' do
    let(:public_market) { create(:public_market, selected_optional_fields: []) }

    it 'can be set to empty array' do
      expect(public_market.selected_optional_fields).to eq([])
    end
  end
end

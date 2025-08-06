# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UniqueAssociationValidator do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'public_markets'

      include UniqueAssociationValidator

      has_and_belongs_to_many :market_attributes
      validates_uniqueness_of_association :market_attributes
    end
  end

  before do
    MarketType.find_or_create_by(code: 'supplies')
  end

  describe '.validates_uniqueness_of_association' do
    let(:editor) { create(:editor) }
    let(:market_attribute1) { create(:market_attribute, key: 'attribute1') }
    let(:market_attribute2) { create(:market_attribute, key: 'attribute2') }
    let(:test_record) do
      # Use PublicMarket as it has the proper setup
      PublicMarket.new(
        editor: editor,
        name: 'Test Market',
        deadline: 1.week.from_now,
        market_type_codes: ['supplies']
      )
    end

    context 'with unique associations' do
      it 'is valid when associations are unique' do
        test_record.market_attributes = [market_attribute1, market_attribute2]
        expect(test_record).to be_valid
      end

      it 'is valid with no associations' do
        test_record.market_attributes = []
        expect(test_record).to be_valid
      end

      it 'is valid with one association' do
        test_record.market_attributes = [market_attribute1]
        expect(test_record).to be_valid
      end
    end

    context 'with duplicate associations' do
      it 'is invalid when associations contain duplicates' do
        # Mock the IDs method to simulate duplicates without hitting database constraints
        allow(test_record).to receive(:market_attribute_ids).and_return([market_attribute1.id, market_attribute1.id, market_attribute2.id])
        expect(test_record).not_to be_valid
        expect(test_record.errors[:market_attributes]).to include('contains duplicates: attribute1')
      end

      it 'includes all duplicate names in error message' do
        # Mock the IDs method to simulate duplicates without hitting database constraints
        allow(test_record).to receive(:market_attribute_ids).and_return([market_attribute1.id, market_attribute1.id, market_attribute2.id, market_attribute2.id])
        expect(test_record).not_to be_valid
        error_message = test_record.errors[:market_attributes].first
        expect(error_message).to include('attribute1')
        expect(error_message).to include('attribute2')
      end
    end
  end

  describe 'MarketType integration' do
    let(:market_type) { build(:market_type, code: 'test_type') }
    let(:attribute1) { create(:market_attribute, key: 'type_attr1') }

    it 'validates uniqueness of market_attributes on new record' do
      # Set up duplicate IDs directly on the unsaved record
      allow(market_type).to receive(:market_attribute_ids).and_return([attribute1.id, attribute1.id])
      expect(market_type).not_to be_valid
      expect(market_type.errors[:market_attributes]).to include('contains duplicates: type_attr1')
    end
  end

  describe 'MarketAttribute integration' do
    let(:market_attribute) { build(:market_attribute, key: 'test_attr') }
    let(:market_type1) { create(:market_type, code: 'type1') }
    let(:public_market1) { create(:public_market) }

    it 'validates uniqueness of market_types on new record' do
      allow(market_attribute).to receive(:market_type_ids).and_return([market_type1.id, market_type1.id])
      expect(market_attribute).not_to be_valid
      expect(market_attribute.errors[:market_types]).to be_present
    end

    it 'validates uniqueness of public_markets on new record' do
      allow(market_attribute).to receive(:public_market_ids).and_return([public_market1.id, public_market1.id])
      expect(market_attribute).not_to be_valid
      expect(market_attribute.errors[:public_markets]).to be_present
    end

    it 'is valid with unique associations' do
      market_type2 = create(:market_type, code: 'type2')
      public_market2 = create(:public_market)

      allow(market_attribute).to receive(:market_type_ids).and_return([market_type1.id, market_type2.id])
      allow(market_attribute).to receive(:public_market_ids).and_return([public_market1.id, public_market2.id])

      expect(market_attribute).to be_valid
    end
  end
end

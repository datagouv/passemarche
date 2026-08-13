# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeSelection, type: :model do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_attribute) { create(:market_attribute) }

  describe 'validations' do
    it 'requires a unique market_attribute per public_market' do
      create(:market_attribute_selection, public_market:, market_attribute:)
      duplicate = build(:market_attribute_selection, public_market:, market_attribute:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:market_attribute_id]).to be_present
    end
  end

  describe 'versioning' do
    it 'creates a version on create' do
      selection = create(:market_attribute_selection, public_market:, market_attribute:)
      expect(selection.versions.map(&:event)).to eq(['create'])
    end

    it 'keeps a destroy version after the record is removed' do
      selection = create(:market_attribute_selection, public_market:, market_attribute:)
      selection.destroy!

      expect(PaperTrail::Version.where(item_type: 'MarketAttributeSelection', item_id: selection.id)
        .order(:id).pluck(:event)).to eq(%w[create destroy])
    end
  end

  describe 'through PublicMarket#market_attributes' do
    it 'creates a version when an attribute is added via <<' do
      public_market.market_attributes << market_attribute

      selection = MarketAttributeSelection.find_by(public_market:, market_attribute:)
      expect(selection.versions.map(&:event)).to eq(['create'])
    end

    it 'keeps a destroy version when deselected via destroy_all on market_attribute_selections' do
      public_market.market_attributes << market_attribute
      selection = MarketAttributeSelection.find_by(public_market:, market_attribute:)

      public_market.market_attribute_selections
        .joins(:market_attribute)
        .where(market_attribute: { key: market_attribute.key })
        .destroy_all

      expect(PaperTrail::Version.where(item_type: 'MarketAttributeSelection', item_id: selection.id)
        .order(:id).pluck(:event)).to eq(%w[create destroy])
    end

    it 'does not create a destroy version when deselected via array assignment' do
      public_market.market_attributes << market_attribute
      selection = MarketAttributeSelection.find_by(public_market:, market_attribute:)

      public_market.market_attributes = public_market.market_attributes - [market_attribute]

      expect(PaperTrail::Version.where(item_type: 'MarketAttributeSelection', item_id: selection.id)
        .pluck(:event)).to eq(['create'])
    end
  end
end

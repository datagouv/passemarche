# frozen_string_literal: true

class DropMarketAttributesPublicMarkets < ActiveRecord::Migration[8.1]
  def up
    drop_table :market_attributes_public_markets
  end

  def down
    create_table :market_attributes_public_markets, id: false do |t|
      t.bigint :market_attribute_id, null: false
      t.bigint :public_market_id, null: false
    end

    add_index :market_attributes_public_markets, %i[market_attribute_id public_market_id],
      name: 'index_market_attributes_public_markets_lookup'
    add_index :market_attributes_public_markets, %i[public_market_id market_attribute_id],
      unique: true, name: 'index_public_markets_attributes_unique'

    restore_legacy_selections
  end

  private

  class LegacyMarketAttributesPublicMarket < ActiveRecord::Base
    self.table_name = 'market_attributes_public_markets'
  end

  def restore_legacy_selections
    pairs = MarketAttributeSelection.pluck(:public_market_id, :market_attribute_id)
    return if pairs.empty?

    rows = pairs.map { |public_market_id, market_attribute_id| { public_market_id:, market_attribute_id: } }
    LegacyMarketAttributesPublicMarket.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations
  end
end

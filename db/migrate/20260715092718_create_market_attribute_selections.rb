# frozen_string_literal: true

class CreateMarketAttributeSelections < ActiveRecord::Migration[8.1]
  def up
    create_table :market_attribute_selections do |t|
      t.references :public_market, null: false, foreign_key: true
      t.references :market_attribute, null: false, foreign_key: true

      t.timestamps
    end

    add_index :market_attribute_selections, %i[public_market_id market_attribute_id],
      unique: true, name: 'index_market_attribute_selections_on_market_and_attribute'

    migrate_existing_selections
  end

  def down
    drop_table :market_attribute_selections
  end

  private

  class LegacyMarketAttributesPublicMarket < ActiveRecord::Base
    self.table_name = 'market_attributes_public_markets'
  end

  def migrate_existing_selections
    now = Time.current
    pairs = LegacyMarketAttributesPublicMarket
      .joins('INNER JOIN public_markets ON public_markets.id = market_attributes_public_markets.public_market_id')
      .pluck(:public_market_id, :market_attribute_id)
    return if pairs.empty?

    rows = pairs.map do |public_market_id, market_attribute_id|
      { public_market_id:, market_attribute_id:, created_at: now, updated_at: now }
    end

    MarketAttributeSelection.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations
  end
end

# frozen_string_literal: true

class RemoveLotNameFromPublicMarkets < ActiveRecord::Migration[8.0]
  class MigrationPublicMarket < ApplicationRecord
    self.table_name = 'public_markets'
  end

  class MigrationLot < ApplicationRecord
    self.table_name = 'lots'
  end

  def up
    backfill_lots_from_lot_name
    remove_column :public_markets, :lot_name, :string
  end

  def down
    add_column :public_markets, :lot_name, :string
    backfill_lot_name_from_lots
  end

  private

  def backfill_lots_from_lot_name
    market_ids_with_lots = MigrationLot.distinct.pluck(:public_market_id)

    MigrationPublicMarket
      .where.not(lot_name: [nil, ''])
      .where.not(id: market_ids_with_lots)
      .find_each do |market|
        MigrationLot.create!(
          public_market_id: market.id,
          name: market.lot_name,
          position: 1,
          created_at: Time.current,
          updated_at: Time.current
        )
      end
  end

  def backfill_lot_name_from_lots
    MigrationPublicMarket.find_each do |market|
      lot_name = MigrationLot.where(public_market_id: market.id).order(:position, :id).pick(:name)
      next if lot_name.blank?

      market.update_columns(lot_name: lot_name)
    end
  end
end

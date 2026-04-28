# frozen_string_literal: true

class CreateMarketApplicationLots < ActiveRecord::Migration[8.1]
  def change
    create_table :market_application_lots do |t|
      t.references :market_application, null: false, foreign_key: true
      t.references :lot, null: false, foreign_key: true

      t.timestamps
    end

    add_index :market_application_lots, %i[market_application_id lot_id],
      unique: true,
      name: :index_market_application_lots_unique
  end
end

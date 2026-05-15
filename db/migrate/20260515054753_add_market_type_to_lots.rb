class AddMarketTypeToLots < ActiveRecord::Migration[8.1]
  def change
    add_reference :lots, :platform_market_type, null: true, foreign_key: { to_table: :market_types }
    add_reference :lots, :market_type, null: true, foreign_key: { to_table: :market_types }
  end
end

class AddMarketInfoToPublicMarkets < ActiveRecord::Migration[8.0]
  def change
    add_column :public_markets, :market_name, :string
    add_column :public_markets, :lot_name, :string
    add_column :public_markets, :deadline, :datetime
    add_column :public_markets, :market_type, :string
  end
end

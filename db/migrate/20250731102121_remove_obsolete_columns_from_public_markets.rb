class RemoveObsoleteColumnsFromPublicMarkets < ActiveRecord::Migration[8.0]
  def change
    remove_column :public_markets, :market_type, :string
    remove_column :public_markets, :defense_industry, :boolean
  end
end

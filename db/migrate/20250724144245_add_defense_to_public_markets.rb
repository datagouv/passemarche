class AddDefenseToPublicMarkets < ActiveRecord::Migration[8.0]
  def change
    add_column :public_markets, :defense, :boolean
  end
end

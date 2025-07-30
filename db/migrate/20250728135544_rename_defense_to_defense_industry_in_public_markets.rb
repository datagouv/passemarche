class RenameDefenseToDefenseIndustryInPublicMarkets < ActiveRecord::Migration[8.0]
  def change
    rename_column :public_markets, :defense, :defense_industry
  end
end

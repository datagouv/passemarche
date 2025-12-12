class AddCanCreateDefenseMarketsToEditors < ActiveRecord::Migration[8.1]
  def change
    add_column :editors, :can_create_defense_markets, :boolean, default: false, null: false
  end
end

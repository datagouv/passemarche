class AddPositionToMarketAttributes < ActiveRecord::Migration[8.1]
  def change
    add_column :market_attributes, :position, :integer, default: 0, null: false
    add_index :market_attributes, :position
  end
end

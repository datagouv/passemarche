class AddSubcategoryIdToMarketAttributes < ActiveRecord::Migration[8.1]
  def change
    add_reference :market_attributes, :subcategory, foreign_key: true, null: true
  end
end

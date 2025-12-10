class BackfillMarketAttributePositions < ActiveRecord::Migration[8.1]
  def up
    MarketAttribute.reset_column_information
    MarketAttribute.order(:mandatory, :category_key, :subcategory_key, :key)
                   .each_with_index do |attr, index|
      attr.update_column(:position, index + 1)
    end
  end

  def down
    MarketAttribute.update_all(position: 0)
  end
end

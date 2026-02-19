class AddHiddenToMarketAttributeResponses < ActiveRecord::Migration[8.1]
  def change
    add_column :market_attribute_responses, :hidden, :boolean, default: false
  end
end

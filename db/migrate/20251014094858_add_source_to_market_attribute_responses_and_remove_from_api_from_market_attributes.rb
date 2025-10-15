class AddSourceToMarketAttributeResponsesAndRemoveFromApiFromMarketAttributes < ActiveRecord::Migration[8.0]
  def change
    # Add source enum to market_attribute_responses
    # 0 = manual, 1 = auto, 2 = manual_after_api_failure
    add_column :market_attribute_responses, :source, :integer, default: 0, null: false

    # Remove from_api from market_attributes (can be inferred from api_name presence)
    remove_column :market_attributes, :from_api, :boolean, default: false, null: false
  end
end

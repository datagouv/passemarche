class RemoveSelectedOptionalFieldsFromPublicMarkets < ActiveRecord::Migration[8.0]
  def change
    remove_column :public_markets, :selected_optional_fields, :text, array: true, default: []
    remove_index :public_markets, :selected_optional_fields, if_exists: true
  end
end

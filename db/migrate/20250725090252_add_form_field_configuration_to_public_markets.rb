class AddFormFieldConfigurationToPublicMarkets < ActiveRecord::Migration[8.0]
  def change
    add_column :public_markets, :selected_optional_fields, :text, array: true, default: []
    add_index :public_markets, :selected_optional_fields, using: :gin
  end
end

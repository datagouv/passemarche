class AddApiFieldsToMarketAttributes < ActiveRecord::Migration[8.0]
  def change
    change_table :market_attributes, bulk: true do |t|
      t.string :api_name
      t.string :api_key
      t.index :api_name
      t.index %i[api_name api_key]
    end
  end
end

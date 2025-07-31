class CreateMarketAttributes < ActiveRecord::Migration[8.0]
  def change
    create_table :market_attributes do |t|
      t.string :key, null: false
      t.integer :input_type, null: false, default: 0
      t.string :category_key, null: false
      t.string :subcategory_key, null: false
      t.boolean :from_api, null: false, default: false
      t.boolean :required, null: false, default: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :market_attributes, :key, unique: true
    add_index :market_attributes, :required
    add_index :market_attributes, :deleted_at
    add_index :market_attributes, :input_type

    create_join_table :market_types, :market_attributes do |t|
      t.index %i[market_type_id market_attribute_id], unique: true, name: 'index_market_types_attributes_unique'
      t.index %i[market_attribute_id market_type_id], name: 'index_market_attributes_types_lookup'
    end

    create_join_table :public_markets, :market_attributes do |t|
      t.index %i[public_market_id market_attribute_id], unique: true, name: 'index_public_markets_attributes_unique'
      t.index %i[market_attribute_id public_market_id], name: 'index_market_attributes_public_markets_lookup'
    end
  end
end

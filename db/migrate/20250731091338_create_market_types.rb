class CreateMarketTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :market_types do |t|
      t.string :code, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    rename_column :public_markets, :market_name, :name
    add_column :public_markets, :market_type_codes, :text, array: true, default: []

    add_index :market_types, :code, unique: true
    add_index :market_types, :deleted_at
  end
end

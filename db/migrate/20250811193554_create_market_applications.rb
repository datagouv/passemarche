class CreateMarketApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :market_applications do |t|
      t.string :identifier, null: false
      t.references :public_market, null: false, foreign_key: true
      t.string :siret, limit: 14, default: nil, null: true

      t.timestamps
    end

    add_index :market_applications, :identifier, unique: true
    add_index :market_applications, :siret
  end
end

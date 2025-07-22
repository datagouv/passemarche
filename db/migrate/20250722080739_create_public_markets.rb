class CreatePublicMarkets < ActiveRecord::Migration[8.0]
  def change
    create_table :public_markets do |t|
      t.string :identifier, null: false
      t.references :editor, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end

    add_index :public_markets, :identifier, unique: true
  end
end

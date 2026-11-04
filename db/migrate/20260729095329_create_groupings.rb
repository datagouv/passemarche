class CreateGroupings < ActiveRecord::Migration[8.1]
  def change
    create_table :groupings do |t|
      t.references :public_market, null: false, foreign_key: true
      t.integer :legal_type

      t.timestamps
    end
  end
end

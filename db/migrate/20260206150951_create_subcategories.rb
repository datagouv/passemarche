class CreateSubcategories < ActiveRecord::Migration[8.1]
  def change
    create_table :subcategories do |t|
      t.references :category, null: false, foreign_key: true
      t.string :key, null: false
      t.string :buyer_label
      t.string :candidate_label
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :subcategories, %i[category_id key], unique: true
    add_index :subcategories, :position
    add_index :subcategories, :deleted_at
  end
end

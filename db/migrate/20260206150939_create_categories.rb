class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :key, null: false
      t.string :buyer_label
      t.string :candidate_label
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :categories, :key, unique: true
    add_index :categories, :position
    add_index :categories, :deleted_at
  end
end

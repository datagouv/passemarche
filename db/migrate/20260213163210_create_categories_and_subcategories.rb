# frozen_string_literal: true

class CreateCategoriesAndSubcategories < ActiveRecord::Migration[8.1]
  def change
    create_categories
    create_subcategories
    add_reference :market_attributes, :subcategory, foreign_key: true
  end

  private

  def create_categories
    create_table :categories do |t|
      t.string :key, null: false
      t.string :buyer_label
      t.string :candidate_label
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps

      t.index :key, unique: true
      t.index :position
      t.index :deleted_at
    end
  end

  def create_subcategories
    create_table :subcategories do |t|
      t.references :category, null: false, foreign_key: true
      t.string :key, null: false
      t.string :buyer_label
      t.string :candidate_label
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps

      t.index %i[category_id key], unique: true
      t.index :position
      t.index :deleted_at
    end
  end
end

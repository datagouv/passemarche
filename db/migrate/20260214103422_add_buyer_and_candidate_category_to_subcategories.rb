# frozen_string_literal: true

class AddBuyerAndCandidateCategoryToSubcategories < ActiveRecord::Migration[8.1]
  def up
    add_reference :subcategories, :buyer_category, foreign_key: { to_table: :categories }, null: true
    add_reference :subcategories, :candidate_category, foreign_key: { to_table: :categories }, null: true

    execute <<~SQL.squish
      UPDATE subcategories
      SET buyer_category_id = category_id,
          candidate_category_id = category_id
    SQL
  end

  def down
    remove_reference :subcategories, :buyer_category, foreign_key: { to_table: :categories }
    remove_reference :subcategories, :candidate_category, foreign_key: { to_table: :categories }
  end
end

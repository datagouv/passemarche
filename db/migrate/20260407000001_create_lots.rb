# frozen_string_literal: true

class CreateLots < ActiveRecord::Migration[8.1]
  def change
    create_table :lots do |t|
      t.references :public_market, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :lots, :position
  end
end

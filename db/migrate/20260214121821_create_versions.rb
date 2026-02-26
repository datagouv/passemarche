# frozen_string_literal: true

class CreateVersions < ActiveRecord::Migration[8.1]
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :versions do |t|
      t.bigint   :whodunnit
      t.datetime :created_at
      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false
      t.string   :event,     null: false
      t.text     :object,         limit: TEXT_BYTES
      t.text     :object_changes, limit: TEXT_BYTES
    end
    add_index :versions, %i[item_type item_id]
    add_index :versions, :created_at
    add_index :versions, :whodunnit
  end
end

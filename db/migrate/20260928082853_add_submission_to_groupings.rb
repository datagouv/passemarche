# frozen_string_literal: true

class AddSubmissionToGroupings < ActiveRecord::Migration[8.1]
  def change
    change_table :groupings, bulk: true do |t|
      t.datetime :submitted_at
      t.integer :submission_mode
      t.integer :sync_status, default: 0, null: false
    end
  end
end

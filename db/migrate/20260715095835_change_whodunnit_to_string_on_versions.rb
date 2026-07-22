# frozen_string_literal: true

class ChangeWhodunnitToStringOnVersions < ActiveRecord::Migration[8.1]
  def up
    change_column :versions, :whodunnit, :string, using: 'whodunnit::text'
  end

  def down
    change_column :versions, :whodunnit, :bigint,
      using: "CASE WHEN whodunnit ~ '^\\d+$' THEN whodunnit::bigint ELSE NULL END"
  end
end

# frozen_string_literal: true

class AddPlatformLotsToMarketApplications < ActiveRecord::Migration[8.1]
  def change
    change_table :market_applications, bulk: true do |t|
      t.boolean :lots_locked, default: false, null: false
      t.datetime :lots_changed_by_platform_at
    end
  end
end

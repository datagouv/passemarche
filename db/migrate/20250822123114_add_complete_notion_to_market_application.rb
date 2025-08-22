class AddCompleteNotionToMarketApplication < ActiveRecord::Migration[8.0]
  def change
    add_column :market_applications, :completed_at, :datetime, null: true, default: nil
    add_column :market_applications, :sync_status, :integer, null: false, default: 0

    add_index :market_applications, :sync_status
  end
end

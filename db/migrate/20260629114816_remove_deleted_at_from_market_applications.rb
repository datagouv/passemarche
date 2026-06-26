class RemoveDeletedAtFromMarketApplications < ActiveRecord::Migration[8.1]
  def change
    remove_column :market_applications, :deleted_at, :datetime
  end
end

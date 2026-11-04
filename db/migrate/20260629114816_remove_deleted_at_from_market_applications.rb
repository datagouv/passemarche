class RemoveDeletedAtFromMarketApplications < ActiveRecord::Migration[8.1]
  def change
    return unless column_exists?(:market_applications, :deleted_at)

    remove_column :market_applications, :deleted_at, :datetime
  end
end

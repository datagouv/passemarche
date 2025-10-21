class AddApiFetchStatusToMarketApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :market_applications, :api_fetch_status, :jsonb, default: {}, null: false
  end
end

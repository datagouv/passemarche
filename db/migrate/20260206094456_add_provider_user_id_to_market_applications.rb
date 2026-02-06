class AddProviderUserIdToMarketApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :market_applications, :provider_user_id, :string
    add_index :market_applications, :provider_user_id
  end
end

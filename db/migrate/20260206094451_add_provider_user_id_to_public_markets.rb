class AddProviderUserIdToPublicMarkets < ActiveRecord::Migration[8.1]
  def change
    add_column :public_markets, :provider_user_id, :string
    add_index :public_markets, :provider_user_id
  end
end

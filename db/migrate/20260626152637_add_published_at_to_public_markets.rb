class AddPublishedAtToPublicMarkets < ActiveRecord::Migration[8.1]
  def change
    add_column :public_markets, :published_at, :datetime
  end
end

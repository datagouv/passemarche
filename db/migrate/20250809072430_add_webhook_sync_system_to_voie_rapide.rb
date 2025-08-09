class AddWebhookSyncSystemToVoieRapide < ActiveRecord::Migration[8.0]
  def change
    # Add sync status tracking to public markets
    add_column :public_markets, :sync_status, :integer, null: false, default: 0
    add_index :public_markets, :sync_status
    
    # Add webhook configuration to editors
    add_column :editors, :completion_webhook_url, :string
    add_column :editors, :redirect_url, :string
    add_column :editors, :webhook_secret, :string
    
    add_index :editors, :webhook_secret, unique: true, where: "webhook_secret IS NOT NULL"
  end
end

class AddApplicationModeToMarketApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :market_applications, :application_mode, :integer
  end
end

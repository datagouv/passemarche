# frozen_string_literal: true

class AddStartedAtToMarketApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :market_applications, :started_at, :datetime
  end
end

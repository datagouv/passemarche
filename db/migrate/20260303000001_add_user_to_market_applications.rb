# frozen_string_literal: true

class AddUserToMarketApplications < ActiveRecord::Migration[8.1]
  def change
    add_reference :market_applications, :user, foreign_key: true, null: true
  end
end

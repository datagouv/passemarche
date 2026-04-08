# frozen_string_literal: true

class AddLotLimitToPublicMarkets < ActiveRecord::Migration[8.1]
  def change
    add_column :public_markets, :lot_limit, :integer, null: true
  end
end

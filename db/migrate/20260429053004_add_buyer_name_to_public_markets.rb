# frozen_string_literal: true

class AddBuyerNameToPublicMarkets < ActiveRecord::Migration[8.1]
  def change
    add_column :public_markets, :buyer_name, :string
  end
end

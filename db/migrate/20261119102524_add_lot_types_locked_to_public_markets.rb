# frozen_string_literal: true

class AddLotTypesLockedToPublicMarkets < ActiveRecord::Migration[8.1]
  def change
    add_column :public_markets, :lot_types_locked, :boolean, default: false, null: false
  end
end

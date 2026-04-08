# frozen_string_literal: true

class MarketApplicationLot < ApplicationRecord
  belongs_to :market_application
  belongs_to :lot

  validates :lot_id, uniqueness: { scope: :market_application_id }
end

# frozen_string_literal: true

class MarketAttributeSelection < ApplicationRecord
  has_paper_trail on: %i[create destroy]

  belongs_to :public_market
  belongs_to :market_attribute

  validates :market_attribute_id, uniqueness: { scope: :public_market_id }
end

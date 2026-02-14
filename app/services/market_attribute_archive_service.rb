# frozen_string_literal: true

class MarketAttributeArchiveService < ApplicationService
  def initialize(market_attribute:)
    @market_attribute = market_attribute
  end

  def call
    return false if @market_attribute.archived?

    @market_attribute.soft_delete!
  end
end

# frozen_string_literal: true

class MarketAttributeFilteringService < ApplicationService
  def initialize(public_market)
    @public_market = public_market
  end

  def call
    available_attributes
  end

  private

  attr_reader :public_market

  def available_attributes
    MarketAttribute.joins(:market_types)
      .where(market_types: { code: public_market.market_type_codes })
      .distinct
      .active
      .ordered
  end
end

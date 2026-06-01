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
      .where(market_types: { code: effective_type_codes })
      .distinct
      .active
      .ordered
  end

  def effective_type_codes
    lot_type_codes = public_market.lots
      .includes(:market_type, :platform_market_type)
      .filter_map(&:effective_market_type)
      .map(&:code)
      .uniq
    (public_market.market_type_codes + lot_type_codes).uniq
  end
end

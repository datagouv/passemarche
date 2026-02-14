# frozen_string_literal: true

class MarketAttributeArchiveService < ApplicationServiceObject
  def initialize(market_attribute:)
    super()
    @market_attribute = market_attribute
  end

  def perform
    return add_error(:market_attribute, :already_archived) if @market_attribute.archived?

    @market_attribute.soft_delete!
    @result = @market_attribute
  rescue ActiveRecord::ActiveRecordError => e
    add_error(:base, e.message)
  end
end

# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    service = MarketAttributeQueryService.new(filters: filter_params)
    service.perform
    @market_attributes = service.result
    @stats = SocleDeBaseStatsService.call
    @categories = Category.active.ordered
    @market_types = MarketType.active
  end

  private

  def filter_params
    params.permit(:query, :category, :source, :market_type_id).to_h.symbolize_keys
  end
end

# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @market_attributes = MarketAttribute.active.ordered.includes(:market_types)
    @stats = SocleDeBaseStatsService.call
  end
end

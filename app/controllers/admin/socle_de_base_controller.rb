# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @grouped_attributes = grouped_market_attributes
    @stats = SocleDeBaseStatsService.call
  end

  private

  def grouped_market_attributes
    grouped = MarketAttribute.active.ordered.group_by(&:category_key)

    MarketAttribute::CATEGORY_TABS.each_with_object({}) do |category_key, result|
      next unless grouped[category_key]

      result[category_key] = grouped[category_key].group_by(&:subcategory_key)
    end
  end
end

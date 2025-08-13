# frozen_string_literal: true

class FieldConfigurationImport::BuildFinalStatistics < ApplicationInteractor
  def call
    context.statistics[:total_active_attributes] = MarketAttribute.active.count
    context.statistics[:total_market_types] = MarketType.active.count
    context.statistics[:total_associations] = MarketType
      .active
      .joins(:market_attributes)
      .where(market_attributes: { deleted_at: nil })
      .count
  end
end

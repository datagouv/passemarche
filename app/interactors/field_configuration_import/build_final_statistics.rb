# frozen_string_literal: true

class FieldConfigurationImport::BuildFinalStatistics < ApplicationInteractor
  def call
    context.statistics[:total_active_attributes] = count_active_attributes
    context.statistics[:total_market_types] = count_active_market_types
    context.statistics[:total_associations] = count_active_associations
  end

  private

  def count_active_attributes
    MarketAttribute.active.count
  end

  def count_active_market_types
    MarketType.active.count
  end

  def count_active_associations
    MarketType
      .active
      .joins(:market_attributes)
      .where(market_attributes: { deleted_at: nil })
      .count
  end
end

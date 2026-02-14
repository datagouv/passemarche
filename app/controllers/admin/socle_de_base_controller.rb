# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @market_attributes = MarketAttribute.active.ordered.includes(:market_types)
    @stats = SocleDeBaseStatsService.call
  end

  def reorder
    ordered_ids = params.expect(ordered_ids: [])

    MarketAttribute.transaction do
      ordered_ids.each_with_index do |id, index|
        MarketAttribute.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end
end

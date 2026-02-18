# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  wrap_parameters false
  before_action :require_admin_role!, only: [:reorder]

  def index
    @market_attributes = MarketAttributeQueryService.call(filters: filter_params)
    @stats = SocleDeBaseStatsService.call
    @categories = Category.active.ordered
    @market_types = MarketType.active
  end

  def reorder
    ordered_ids = params.require(:ordered_ids)

    MarketAttribute.transaction do
      ordered_ids.each_with_index do |id, index|
        MarketAttribute.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end

  private

  def filter_params
    params.permit(:query, :category, :source, :market_type_id).to_h.symbolize_keys
  end
end

# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  wrap_parameters false
  before_action :require_admin_role!, only: [:reorder]

  def index
    @market_attributes = query_attributes
    @stats = SocleDeBaseStatsService.call
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

  def export
    attributes = query_attributes
    service = ExportSocleDeBaseCsvService.new(market_attributes: attributes)
    service.perform

    send_data service.result[:csv_data],
      filename: service.result[:filename],
      type: 'text/csv; charset=utf-8'
  end

  private

  def query_attributes
    query = MarketAttributeQueryService.new(filters: export_filters)
    query.perform
    query.result
  end

  def export_filters
    params.permit(:category, :subcategory, :source, :mandatory, :market_type_id).to_h.symbolize_keys
  end
end

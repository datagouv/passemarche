# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @market_attributes = query_attributes
    @stats = SocleDeBaseStatsService.call
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

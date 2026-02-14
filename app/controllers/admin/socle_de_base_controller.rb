# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @market_attributes = MarketAttribute.active.ordered.includes(:market_types)
    @stats = SocleDeBaseStatsService.call
  end

  def archive
    attribute = MarketAttribute.find(params[:id])
    service = MarketAttributeArchiveService.new(market_attribute: attribute)
    service.perform

    if service.success?
      redirect_to admin_socle_de_base_index_path,
        notice: t('.success', key: attribute.key)
    else
      redirect_to admin_socle_de_base_index_path,
        alert: t('.already_archived')
    end
  end
end

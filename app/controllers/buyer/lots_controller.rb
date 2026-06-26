# frozen_string_literal: true

module Buyer
  class LotsController < ApplicationController
    before_action :find_public_market
    before_action :check_market_not_published

    def update_types
      market_type = MarketType.find_by(id: params[:market_type_id])
      update_lot_types(market_type)
      render turbo_stream: turbo_streams_for_updated_lots
    end

    private

    def update_lot_types(market_type)
      @updated_lot_ids = Array(params[:lot_ids]).map(&:to_i)
      @public_market.update_lot_types(@updated_lot_ids, market_type)
    end

    def turbo_streams_for_updated_lots
      @public_market.lots.ordered
        .includes(:platform_market_type, :market_type)
        .where(id: @updated_lot_ids)
        .map do |lot|
          turbo_stream.replace("lot_row_#{lot.id}",
            partial: 'buyer/public_markets/lot_row',
            locals: { lot: })
        end
    end

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end

    def check_market_not_published
      return unless @public_market.published?

      render plain: t('buyer.public_markets.market_published_cannot_edit'), status: :unprocessable_content
    end
  end
end

# frozen_string_literal: true

module Buyer
  class SyncStatusController < ApplicationController
    before_action :find_public_market

    def show
      respond_to do |format|
        format.html
        format.json do
          set_no_cache_headers
          render json: sync_status_response
        end
      end
    end

    private

    def sync_status_response
      { sync_status: @public_market.sync_status }
    end

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end
  end
end

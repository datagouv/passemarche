# frozen_string_literal: true

module Candidate
  class SyncStatusController < ApplicationController
    before_action :find_market_application

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
      { sync_status: @market_application.sync_status }
    end

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'La candidature recherché n\'a pas été trouvé', status: :not_found
    end
  end
end

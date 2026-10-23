# frozen_string_literal: true

module Candidate
  class SyncStatusController < Candidate::ApplicationController
    prepend_before_action :find_market_application
    before_action :redirect_co_traitant_before_transmission, only: :show

    def show
      @presenter = MarketApplicationPresenter.new(@market_application)

      respond_to do |format|
        format.html
        format.json do
          set_no_cache_headers
          render json: sync_status_response
        end
      end
    end

    private

    def redirect_co_traitant_before_transmission
      return unless @market_application.co_traitant_of_grouping? && !@market_application.completed?

      redirect_to grouping_dashboard_candidate_market_application_path(@market_application.identifier)
    end

    def sync_status_response
      { sync_status: @market_application.sync_status }
    end

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render_market_application_not_found
    end
  end
end

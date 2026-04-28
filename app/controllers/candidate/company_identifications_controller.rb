# frozen_string_literal: true

module Candidate
  class CompanyIdentificationsController < Candidate::ApplicationController
    include Candidate::MarketApplicationGuard

    prepend_before_action :find_market_application

    def show; end

    def update
      enqueue_api_data_fetch_if_needed

      if @market_application.public_market.lots.any?
        redirect_to lot_selection_candidate_market_application_path(@market_application.identifier)
      else
        redirect_to step_candidate_market_application_path(@market_application.identifier, :api_data_recovery_status)
      end
    end

    private

    def find_market_application
      @market_application = MarketApplication
        .includes(public_market: :lots)
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def enqueue_api_data_fetch_if_needed
      Candidate::EnqueueApiDataFetch.call(market_application: @market_application)
    end
  end
end

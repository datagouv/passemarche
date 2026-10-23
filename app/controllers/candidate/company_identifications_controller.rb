# frozen_string_literal: true

module Candidate
  class CompanyIdentificationsController < Candidate::ApplicationController
    include Candidate::MarketApplicationGuard
    include Candidate::ApplicationModeGuard

    prepend_before_action :find_market_application

    def show; end

    def update
      enqueue_api_data_fetch_if_needed
      redirect_to step_after_company_identification_path(@market_application)
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
      return unless @market_application.step_after_company_identification == :api_data_recovery_status

      Candidate::EnqueueApiDataFetch.call(market_application: @market_application)
    end
  end
end

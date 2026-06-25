# frozen_string_literal: true

module Candidate
  class DeadlinePassedController < Candidate::ApplicationController
    prepend_before_action :find_market_application
    before_action :check_market_still_open

    def show; end

    private

    def check_market_still_open
      return unless @market_application.public_market.open?

      redirect_to step_candidate_market_application_path(@market_application.identifier, :company_identification)
    end

    def find_market_application
      @market_application = MarketApplication
        .includes(public_market: :editor)
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end
  end
end

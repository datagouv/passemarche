# frozen_string_literal: true

module Candidate
  class DeadlinePassedController < Candidate::ApplicationController
    include Candidate::StatusPageApplication

    before_action :check_market_still_open

    def show; end

    private

    def check_market_still_open
      return unless @market_application.public_market.open?

      redirect_to step_candidate_market_application_path(@market_application.identifier, :company_identification)
    end
  end
end

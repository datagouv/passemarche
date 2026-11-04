# frozen_string_literal: true

module Candidate
  class LockedApplicationsController < Candidate::ApplicationController
    include Candidate::StatusPageApplication
    include Candidate::GroupementFeatureGuard

    before_action :redirect_unless_locked_co_traitant

    def show; end

    private

    def redirect_unless_locked_co_traitant
      return if @market_application.co_traitant_of_grouping? && @market_application.lock_reason == :grouping_submitted

      redirect_to step_candidate_market_application_path(@market_application.identifier, :market_information)
    end
  end
end

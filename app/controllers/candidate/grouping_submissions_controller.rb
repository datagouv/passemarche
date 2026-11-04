# frozen_string_literal: true

module Candidate
  class GroupingSubmissionsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MandataireGroupingGuard

    before_action :redirect_unless_submitted, only: :show

    def show
      @grouping = grouping
    end

    def create
      result = SubmitGrouping.call(grouping:, submission_mode: params[:submission_mode])

      if result.success?
        redirect_to grouping_submission_candidate_market_application_path(@market_application.identifier)
      else
        redirect_to grouping_dashboard_candidate_market_application_path(@market_application.identifier), alert: result.message
      end
    end

    private

    def redirect_unless_submitted
      return if grouping.submitted?

      redirect_to grouping_dashboard_candidate_market_application_path(@market_application.identifier)
    end
  end
end

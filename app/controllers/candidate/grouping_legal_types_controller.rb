# frozen_string_literal: true

module Candidate
  class GroupingLegalTypesController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::MandataireGroupingGuard

    def show
      @grouping = grouping
    end

    def update
      result = Candidate::SetGroupingLegalType.call(
        market_application: @market_application,
        legal_type: params[:legal_type]
      )

      return handle_success if result.success?

      @grouping = grouping
      @errors = result.errors
      render :show, status: :unprocessable_content
    end

    private

    def handle_success
      redirect_to company_identification_candidate_market_application_path(@market_application.identifier)
    end
  end
end

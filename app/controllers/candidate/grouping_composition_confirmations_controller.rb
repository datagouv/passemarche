# frozen_string_literal: true

module Candidate
  class GroupingCompositionConfirmationsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::MandataireGroupingGuard

    before_action :redirect_to_composition_if_no_co_traitant, only: :show

    def show
      @grouping = grouping
    end

    def update
      result = Candidate::ConfirmGroupingComposition.call(grouping:)
      return redirect_to candidate_dashboard_path, notice: t('candidate.grouping_compositions.success') if result.success?

      @grouping = grouping
      @errors = result.errors
      render :show, status: :unprocessable_content
    end

    private

    def redirect_to_composition_if_no_co_traitant
      return if grouping.grouping_members.co_traitant.any?

      redirect_to grouping_composition_candidate_market_application_path(@market_application.identifier)
    end
  end
end

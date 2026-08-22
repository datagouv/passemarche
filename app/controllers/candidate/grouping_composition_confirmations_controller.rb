# frozen_string_literal: true

module Candidate
  class GroupingCompositionConfirmationsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard

    prepend_before_action :find_market_application
    before_action :redirect_unless_mandataire
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

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def redirect_unless_mandataire
      return if grouping

      redirect_to application_mode_candidate_market_application_path(@market_application.identifier)
    end

    def redirect_to_composition_if_no_co_traitant
      return if grouping.grouping_members.co_traitant.any?

      redirect_to grouping_composition_candidate_market_application_path(@market_application.identifier)
    end

    def grouping
      return @grouping if defined?(@grouping)

      @grouping = Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: @market_application.id })
    end
  end
end

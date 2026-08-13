# frozen_string_literal: true

module Candidate
  class GroupingLegalTypesController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard

    prepend_before_action :find_market_application
    before_action :redirect_unless_mandataire

    def show; end

    def update
      result = Candidate::SetGroupingLegalType.call(
        market_application: @market_application,
        legal_type: params[:legal_type]
      )

      return handle_success if result.success?

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
      @grouping = Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: @market_application.id })
      return if @grouping

      redirect_to application_mode_candidate_market_application_path(@market_application.identifier)
    end

    def handle_success
      redirect_to company_identification_candidate_market_application_path(@market_application.identifier)
    end
  end
end

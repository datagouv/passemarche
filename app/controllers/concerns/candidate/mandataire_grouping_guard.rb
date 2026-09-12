# frozen_string_literal: true

module Candidate
  module MandataireGroupingGuard
    extend ActiveSupport::Concern

    included do
      prepend_before_action :find_market_application
      before_action :redirect_unless_mandataire
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

    def grouping
      return @grouping if defined?(@grouping)

      @grouping = Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: @market_application.id })
    end
  end
end

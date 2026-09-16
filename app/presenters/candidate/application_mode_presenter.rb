# frozen_string_literal: true

module Candidate
  class ApplicationModePresenter
    def initialize(market_application)
      @market_application = market_application
    end

    def already_mandataire?
      market_application.already_mandataire_elsewhere?
    end

    def readonly?
      market_application.application_mode.present?
    end

    def mixte?
      solo_application.present? && groupement_application.present?
    end

    def solo_selected?
      return false if mixte?

      solo_application.present?
    end

    def groupement_selected?
      return false if mixte?

      groupement_application.present?
    end

    private

    attr_reader :market_application

    def solo_application
      market_application.solo? ? market_application : market_application.solo_counterpart
    end

    def groupement_application
      market_application.groupement? ? market_application : market_application.groupement_counterpart
    end
  end
end

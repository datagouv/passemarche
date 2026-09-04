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

    private

    attr_reader :market_application
  end
end

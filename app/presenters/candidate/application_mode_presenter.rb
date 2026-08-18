# frozen_string_literal: true

module Candidate
  class ApplicationModePresenter
    def initialize(market_application)
      @market_application = market_application
    end

    def already_mandataire?
      Grouping
        .joins(:mandataire_market_application)
        .where(public_market: market_application.public_market, market_applications: { siret: market_application.siret })
        .where.not(market_applications: { id: market_application.id })
        .exists?
    end

    def readonly?
      market_application.application_mode.present?
    end

    private

    attr_reader :market_application
  end
end

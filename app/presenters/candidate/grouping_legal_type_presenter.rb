# frozen_string_literal: true

module Candidate
  class GroupingLegalTypePresenter
    def initialize(market_application)
      @market_application = market_application
    end

    def grouping
      return @grouping if defined?(@grouping)

      @grouping = Grouping.joins(:mandataire_market_application)
        .find_by(market_applications: { id: market_application.id })
    end

    private

    attr_reader :market_application
  end
end

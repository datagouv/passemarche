# frozen_string_literal: true

module Candidate
  class StartMarketApplication < ApplicationInteractor
    delegate :market_application, to: :context

    def call
      return unless market_application.mark_started!

      MarketApplicationStartedWebhookJob.perform_later(market_application.id, started_at: market_application.started_at)
    end
  end
end

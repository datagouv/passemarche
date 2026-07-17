# frozen_string_literal: true

class QueueMarketApplicationWebhook < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    MarketApplicationWebhookJob.perform_later(market_application.id)
  end
end

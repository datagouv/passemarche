# frozen_string_literal: true

class QueueMarketApplicationWebhook < ApplicationInteractor
  delegate :market_application, :request_host, :request_protocol, to: :context

  def call
    MarketApplicationWebhookJob.perform_later(
      market_application.id,
      request_host:,
      request_protocol:
    )
  end
end

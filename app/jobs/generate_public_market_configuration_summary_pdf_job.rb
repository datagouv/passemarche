# frozen_string_literal: true

class GeneratePublicMarketConfigurationSummaryPdfJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(public_market_id, request_host: nil, request_protocol: nil)
    public_market = PublicMarket.find(public_market_id)

    GeneratePublicMarketConfigurationSummaryPdf.call(public_market:)

    PublicMarketWebhookJob.perform_later(public_market_id, request_host:, request_protocol:)
  end
end

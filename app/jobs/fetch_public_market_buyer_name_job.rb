# frozen_string_literal: true

class FetchPublicMarketBuyerNameJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(public_market_id)
    public_market = PublicMarket.find(public_market_id)
    result = FetchBuyerName.call(public_market:)

    return unless result.success? && result.buyer_name.present?

    public_market.update!(buyer_name: result.buyer_name)
  end
end

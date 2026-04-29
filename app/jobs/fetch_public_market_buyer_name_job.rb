# frozen_string_literal: true

class FetchPublicMarketBuyerNameJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(public_market_id)
    public_market = PublicMarket.find(public_market_id)
    result = Insee.call(params: { siret: public_market.siret }, public_market:)

    return unless result.success?

    buyer_name = result.bundled_data&.data&.social_reason
    public_market.update!(buyer_name:) if buyer_name.present?
  end
end

# frozen_string_literal: true

# Webhook job for PublicMarket completion events
class PublicMarketWebhookJob < WebhookJob
  include WebhookSyncable

  private

  def find_entity(entity_id)
    PublicMarket.find(entity_id)
  end

  def entity_payload(entity)
    {
      event: 'market.completed',
      timestamp: entity.completed_at.iso8601,
      market: market_payload(entity)
    }
  end

  def market_payload(entity)
    {
      identifier: entity.identifier,
      name: entity.name,
      lots: entity.lots.ordered.map { |lot| lot_payload(lot) },
      market_type_codes: entity.market_type_codes,
      completed_at: entity.completed_at.iso8601,
      field_keys: entity.market_attributes.pluck(:key),
      configuration_summary_url: configuration_summary_url_for(entity)
    }
  end

  def configuration_summary_url_for(entity)
    return nil unless entity.configuration_summary.attached?

    Rails.application.routes.url_helpers.configuration_summary_api_v1_public_market_url(entity.identifier)
  end

  def lot_payload(lot)
    {
      id: lot.id,
      name: lot.name,
      cpv_code: lot.cpv_code,
      market_type_code: lot.effective_market_type&.code
    }
  end
end

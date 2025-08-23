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
      market: {
        identifier: entity.identifier,
        name: entity.name,
        lot_name: entity.lot_name,
        market_type_codes: entity.market_type_codes,
        completed_at: entity.completed_at.iso8601,
        field_keys: entity.market_attributes.pluck(:key)
      }
    }
  end
end

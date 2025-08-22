# frozen_string_literal: true

# Webhook job for MarketApplication completion events
class MarketApplicationWebhookJob < WebhookJob
  include WebhookSyncable

  private

  def find_entity(entity_id)
    MarketApplication.find(entity_id)
  end

  def entity_payload(entity)
    {
      event: 'market_application.completed',
      timestamp: entity.completed_at.iso8601,
      market_identifier: entity.public_market.identifier,
      market_application: {
        identifier: entity.identifier
      }
    }
  end
end

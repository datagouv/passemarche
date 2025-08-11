# frozen_string_literal: true

# Webhook job for PublicMarket completion events
class PublicMarketWebhookJob < WebhookJob
  private

  def find_entity(entity_id)
    PublicMarket.find(entity_id)
  end

  def skip_delivery?(entity)
    entity.sync_completed?
  end

  def before_delivery_callback(entity)
    entity.update!(sync_status: :sync_processing)
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

  def entity_webhook_url(entity)
    entity.editor.completion_webhook_url
  end

  def entity_webhook_secret(entity)
    entity.editor.webhook_secret
  end

  def on_success_callback(entity)
    entity.update!(sync_status: :sync_completed)
  end

  def on_error_callback(entity)
    entity.update!(sync_status: :sync_failed)
  end
end

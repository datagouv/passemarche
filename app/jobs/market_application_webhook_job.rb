# frozen_string_literal: true

# Webhook job for MarketApplication completion events
class MarketApplicationWebhookJob < WebhookJob
  private

  def find_entity(entity_id)
    MarketApplication.find(entity_id)
  end

  def skip_delivery?(entity)
    entity.sync_completed?
  end

  def before_delivery_callback(entity)
    entity.update!(sync_status: :sync_processing)
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

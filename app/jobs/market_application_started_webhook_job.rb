# frozen_string_literal: true

class MarketApplicationStartedWebhookJob < WebhookJob
  def perform(entity_id, started_at:)
    @started_at = started_at
    super(entity_id)
  end

  private

  def find_entity(entity_id)
    MarketApplication.find(entity_id)
  end

  def skip_delivery?(entity)
    entity.started_at != @started_at || entity.completed_at? || !entity.editor.webhook_configured?
  end

  def entity_webhook_url(entity)
    entity.editor.completion_webhook_url
  end

  def entity_webhook_secret(entity)
    entity.editor.webhook_secret
  end

  def entity_payload(entity)
    {
      event: 'market_application.started',
      timestamp: entity.started_at.iso8601,
      market_identifier: entity.public_market.identifier,
      market_application: {
        identifier: entity.identifier,
        siret: entity.siret,
        status: 'in_progress'
      }
    }
  end
end

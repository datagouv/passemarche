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
        identifier: entity.identifier,
        siret: entity.siret,
        attestation_url: attestation_url_for(entity)
      }
    }
  end

  def attestation_url_for(entity)
    # Parse the base URL to extract host and port
    uri = URI.parse(Rails.application.config.api_base_url)

    Rails.application.routes.url_helpers.attestation_api_v1_market_application_url(
      entity.identifier,
      host: uri.host,
      port: uri.port == uri.default_port ? nil : uri.port,
      protocol: uri.scheme
    )
  end
end

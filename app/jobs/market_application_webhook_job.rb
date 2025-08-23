# frozen_string_literal: true

# Webhook job for MarketApplication completion events
class MarketApplicationWebhookJob < WebhookJob
  include WebhookSyncable

  def perform(entity_id, request_host: nil, request_protocol: nil)
    @request_host = request_host
    @request_protocol = request_protocol
    super(entity_id)
  end

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
        attestation_url: attestation_url_for(entity),
        documents_package_url: documents_package_url_for(entity)
      }
    }
  end

  def attestation_url_for(entity)
    Rails.application.routes.url_helpers.attestation_api_v1_market_application_url(
      entity.identifier,
      host: @request_host,
      protocol: @request_protocol
    )
  end

  def documents_package_url_for(entity)
    uri = URI.parse(Rails.application.config.api_base_url)

    Rails.application.routes.url_helpers.documents_package_api_v1_market_application_url(
      entity.identifier,
      host: uri.host,
      port: uri.port == uri.default_port ? nil : uri.port,
      protocol: uri.scheme
    )
  end
end

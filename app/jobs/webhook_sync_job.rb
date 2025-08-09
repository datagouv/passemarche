# frozen_string_literal: true

class WebhookSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(public_market_id)
    public_market = PublicMarket.find(public_market_id)
    return if public_market.sync_completed?

    sync_webhook(public_market)
  rescue ActiveRecord::RecordNotFound
    raise
  rescue StandardError => e
    public_market&.update!(sync_status: :sync_failed)
    raise e
  end

  private

  def sync_webhook(public_market)
    public_market.update!(sync_status: :sync_processing)

    payload = build_webhook_payload(public_market)
    success = deliver_webhook(public_market.editor, payload)

    if success
      public_market.update!(sync_status: :sync_completed)
    else
      public_market.update!(sync_status: :sync_failed)
      raise 'Webhook delivery failed'
    end
  end

  def deliver_webhook(editor, payload)
    return false unless editor.webhook_configured?

    response = make_webhook_request(editor, payload)
    response.success?
  rescue StandardError => e
    Rails.logger.error "Webhook delivery error: #{e.message}"
    false
  end

  def make_webhook_request(editor, payload)
    Faraday.post(editor.completion_webhook_url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Webhook-Signature-SHA256'] = generate_signature(editor, payload) if editor.webhook_secret.present?
      req.body = payload.to_json
      req.options.timeout = 30
    end
  end

  def generate_signature(editor, payload)
    "sha256=#{editor.webhook_signature(payload.to_json)}"
  end

  def build_webhook_payload(public_market)
    {
      event: 'market.completed',
      timestamp: public_market.completed_at.iso8601,
      market: {
        identifier: public_market.identifier,
        name: public_market.name,
        lot_name: public_market.lot_name,
        market_type_codes: public_market.market_type_codes,
        completed_at: public_market.completed_at.iso8601,
        field_keys: public_market.market_attributes.pluck(:key)
      }
    }
  end
end

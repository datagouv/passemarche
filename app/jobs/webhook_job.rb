# frozen_string_literal: true

# Abstract base class for webhook delivery jobs
class WebhookJob < ApplicationJob
  queue_as :default

  retry_on WebhookRetryableError, wait: :polynomially_longer, attempts: 3 do |job, error|
    entity = job.arguments.first
    entity = job.send(:find_entity, entity) if entity.is_a?(Integer) || entity.is_a?(String)
    job.send(:on_error_callback, entity) if entity

    BugTrackerService.capture_exception(error, {
      job: job.class.name,
      entity_id: job.arguments.first,
      message: 'All retries exhausted'
    })
  end

  def perform(entity_id)
    entity = find_entity(entity_id)
    return if skip_delivery?(entity)

    process_webhook_delivery(entity)
  rescue ActiveRecord::RecordNotFound => e
    BugTrackerService.capture_exception(e, {
      job: self.class.name,
      entity_id:,
      message: 'Entity not found - possible race condition or data integrity issue'
    })
  rescue WebhookNonRetryableError => e
    on_error_callback(entity) if entity

    BugTrackerService.capture_exception(e, {
      job: self.class.name,
      entity_id:,
      entity_class: entity&.class&.name
    })
  end

  private

  def find_entity(entity_id)
    raise NotImplementedError, "#{self.class} must implement #find_entity"
  end

  def entity_payload(entity)
    raise NotImplementedError, "#{self.class} must implement #entity_payload"
  end

  def entity_webhook_url(entity)
    raise NotImplementedError, "#{self.class} must implement #entity_webhook_url"
  end

  def entity_webhook_secret(entity)
    raise NotImplementedError, "#{self.class} must implement #entity_webhook_secret"
  end

  def skip_delivery?(_entity)
    false
  end

  def process_webhook_delivery(entity)
    before_delivery_callback(entity)

    payload = entity_payload(entity)
    webhook_url = entity_webhook_url(entity)
    webhook_secret = entity_webhook_secret(entity)

    deliver_webhook(webhook_url, webhook_secret, payload, entity)
    on_success_callback(entity)
  end

  def before_delivery_callback(entity); end

  def on_success_callback(entity); end

  def on_error_callback(entity); end

  def deliver_webhook(webhook_url, webhook_secret, payload, entity)
    return handle_missing_url(entity) if webhook_url.blank?

    response = make_webhook_request(webhook_url, webhook_secret, payload)
    analyze_response_and_handle_errors(response, webhook_url, entity)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Net::OpenTimeout, Net::ReadTimeout => e
    raise WebhookRetryableError, "Network error delivering webhook: #{e.message}"
  rescue Faraday::SSLError => e
    raise WebhookNonRetryableError, "SSL error delivering webhook: #{e.message}"
  end

  def make_webhook_request(webhook_url, webhook_secret, payload)
    Faraday.post(webhook_url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Webhook-Signature-SHA256'] = generate_signature(webhook_secret, payload) if webhook_secret.present?
      req.body = payload.to_json
      req.options.timeout = 30
    end
  end

  def analyze_response_and_handle_errors(response, webhook_url, _entity)
    case response.status
    when 200..299
      true
    when 408, 429, 500..599
      raise_retryable_error(response, webhook_url)
    when 400, 401, 403, 404, 405, 410, 422
      raise_non_retryable_error(response, webhook_url)
    else
      Rails.logger.warn "Unexpected HTTP status #{response.status} from webhook"
      raise_retryable_error(response, webhook_url, 'Unexpected')
    end
  end

  def raise_retryable_error(response, webhook_url, prefix = nil)
    message = prefix ? "#{prefix} HTTP #{response.status}" : "HTTP #{response.status}"
    raise WebhookRetryableError.new(
      "#{message} from #{webhook_url}",
      http_status: response.status,
      response_body: response.body&.truncate(500)
    )
  end

  def raise_non_retryable_error(response, webhook_url)
    raise WebhookNonRetryableError.new(
      "HTTP #{response.status} from #{webhook_url}",
      http_status: response.status,
      response_body: response.body&.truncate(500)
    )
  end

  def handle_missing_url(entity)
    BugTrackerService.capture_message(
      'Webhook URL is blank for entity',
      level: :warn,
      context: {
        entity_class: entity.class.name,
        entity_id: entity.id
      }
    )
    raise WebhookNonRetryableError, 'No webhook URL configured'
  end

  def generate_signature(webhook_secret, payload)
    return nil if webhook_secret.blank?

    signature = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload.to_json)
    "sha256=#{signature}"
  end
end

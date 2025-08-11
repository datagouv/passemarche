# frozen_string_literal: true

class WebhookRetryableError < StandardError
  attr_reader :http_status, :response_body

  def initialize(message, http_status: nil, response_body: nil)
    super(message)
    @http_status = http_status
    @response_body = response_body
  end
end

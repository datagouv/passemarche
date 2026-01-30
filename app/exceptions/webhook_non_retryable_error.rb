# frozen_string_literal: true

class WebhookNonRetryableError < ApplicationError
  attr_reader :http_status, :response_body

  def initialize(message, http_status: nil, response_body: nil, context: {})
    @http_status = http_status
    @response_body = response_body
    super(message, context: context.merge(http_status:, response_body:).compact)
  end
end

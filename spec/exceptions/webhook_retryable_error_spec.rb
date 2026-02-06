# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhookRetryableError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts http_status and response_body' do
      error = described_class.new(
        'Webhook failed',
        http_status: 503,
        response_body: 'Service Unavailable'
      )

      expect(error.message).to eq('Webhook failed')
      expect(error.http_status).to eq(503)
      expect(error.response_body).to eq('Service Unavailable')
    end

    it 'includes attributes in context' do
      error = described_class.new('Failed', http_status: 500)

      expect(error.context).to include(http_status: 500)
    end

    it 'supports to_h serialization' do
      error = described_class.new('Failed', http_status: 502)

      expect(error.to_h).to include(
        error_class: 'WebhookRetryableError',
        message: 'Failed'
      )
    end
  end
end

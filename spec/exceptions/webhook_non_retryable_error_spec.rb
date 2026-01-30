# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhookNonRetryableError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts http_status and response_body' do
      error = described_class.new(
        'Webhook permanently failed',
        http_status: 404,
        response_body: 'Not Found'
      )

      expect(error.message).to eq('Webhook permanently failed')
      expect(error.http_status).to eq(404)
      expect(error.response_body).to eq('Not Found')
    end

    it 'includes attributes in context' do
      error = described_class.new('Failed', http_status: 400)

      expect(error.context).to include(http_status: 400)
    end

    it 'supports to_h serialization' do
      error = described_class.new('Failed', http_status: 422)

      expect(error.to_h).to include(
        error_class: 'WebhookNonRetryableError',
        message: 'Failed'
      )
    end
  end
end

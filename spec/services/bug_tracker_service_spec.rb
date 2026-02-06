# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BugTrackerService do
  describe '.capture_exception' do
    let(:exception) { StandardError.new('Test error') }
    let(:context) { { user_id: 123, action: 'test' } }

    it 'sends exception to Sentry' do
      expect(Sentry).to receive(:capture_exception).with(exception, extra: context)

      described_class.capture_exception(exception, context)
    end

    it 'logs exception details to Rails logger' do
      allow(Sentry).to receive(:capture_exception)

      expect(Rails.logger).to receive(:error).with(/Exception: StandardError - Test error/)
      expect(Rails.logger).to receive(:error).with(/Context:/)

      described_class.capture_exception(exception, context)
    end

    context 'when exception has backtrace' do
      before do
        allow(exception).to receive(:backtrace).and_return(['line 1', 'line 2'])
        allow(Sentry).to receive(:capture_exception)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the backtrace' do
        expect(Rails.logger).to receive(:error).with(/Backtrace/)

        described_class.capture_exception(exception)
      end
    end

    context 'when exception has HTTP metadata' do
      let(:webhook_error) do
        WebhookRetryableError.new('Webhook failed', http_status: 500, response_body: 'Server Error')
      end

      before do
        allow(Sentry).to receive(:capture_exception)
      end

      it 'logs HTTP status and response body' do
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error).with(/HTTP Status: 500/)
        expect(Rails.logger).to receive(:error).with(/Response Body: Server Error/)

        described_class.capture_exception(webhook_error)
      end
    end
  end

  describe '.capture_message' do
    let(:message) { 'Test message' }
    let(:context) { { key: 'value' } }

    it 'sends message to Sentry' do
      expect(Sentry).to receive(:capture_message).with(message, level: :error, extra: context)

      described_class.capture_message(message, context:)
    end

    it 'logs message to Rails logger' do
      allow(Sentry).to receive(:capture_message)

      expect(Rails.logger).to receive(:error).with(/Test message/)
      expect(Rails.logger).to receive(:error).with(/Context:/)

      described_class.capture_message(message, context:)
    end

    it 'uses specified log level' do
      allow(Sentry).to receive(:capture_message)

      expect(Rails.logger).to receive(:warn).with(/Test message/)

      described_class.capture_message(message, level: :warn, context: {})
    end

    it 'sends correct level to Sentry' do
      expect(Sentry).to receive(:capture_message).with(message, level: :warn, extra: {})

      described_class.capture_message(message, level: :warn)
    end
  end
end

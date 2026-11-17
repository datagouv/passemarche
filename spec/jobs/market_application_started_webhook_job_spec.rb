# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe MarketApplicationStartedWebhookJob, type: :job do
  let(:editor) { create(:editor, completion_webhook_url: 'https://example.com/webhook', webhook_secret: 'secret') }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:started_at) { Time.zone.local(2026, 11, 17, 10, 30) }
  let(:market_application) { create(:market_application, public_market:, siret: '12345678901234', started_at:) }

  before do
    WebMock.enable!
    stub_request(:post, editor.completion_webhook_url).to_return(status: 200, body: 'OK')
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  after do
    WebMock.disable!
    WebMock.reset!
  end

  describe '#perform' do
    it 'notifies the platform that the application is in progress' do
      described_class.perform_now(market_application.id, started_at:)

      expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
        .with(body: {
          event: 'market_application.started',
          timestamp: started_at.iso8601,
          market_identifier: public_market.identifier,
          market_application: {
            identifier: market_application.identifier,
            siret: '12345678901234',
            status: 'in_progress'
          }
        }.to_json)
    end

    it 'signs the payload with the editor secret' do
      described_class.perform_now(market_application.id, started_at:)

      expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
        .with(headers: { 'X-Webhook-Signature-SHA256' => /\Asha256=\h{64}\z/ })
    end

    it 'leaves the transmission synchronization untouched' do
      expect { described_class.perform_now(market_application.id, started_at:) }
        .not_to(change { market_application.reload.sync_status })
    end

    it 'does not notify when the application has been reopened since' do
      market_application.update!(started_at: nil)

      described_class.perform_now(market_application.id, started_at:)

      expect(WebMock).not_to have_requested(:post, editor.completion_webhook_url)
    end

    it 'does not notify when the application has been started again since' do
      market_application.update!(started_at: started_at + 1.day)

      described_class.perform_now(market_application.id, started_at:)

      expect(WebMock).not_to have_requested(:post, editor.completion_webhook_url)
    end

    it 'does not notify when the application has been transmitted since' do
      market_application.update!(completed_at: started_at + 1.hour)

      described_class.perform_now(market_application.id, started_at:)

      expect(WebMock).not_to have_requested(:post, editor.completion_webhook_url)
    end

    it 'does not notify when the editor has no webhook configured' do
      editor.update!(completion_webhook_url: nil)

      described_class.perform_now(market_application.id, started_at:)

      expect(WebMock).not_to have_requested(:post, 'https://example.com/webhook')
    end

    it 'retries when the platform is unavailable' do
      stub_request(:post, editor.completion_webhook_url).to_return(status: 503)

      expect { described_class.perform_now(market_application.id, started_at:) }
        .to have_enqueued_job(described_class).with(market_application.id, started_at:)
    end
  end
end

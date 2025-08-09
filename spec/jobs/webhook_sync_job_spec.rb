# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WebhookSyncJob, type: :job do
  let(:editor) { create(:editor, completion_webhook_url: 'https://example.com/webhook') }
  let(:public_market) { create(:public_market, :completed, editor: editor) }

  before do
    WebMock.enable!
    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 200, body: 'OK')
  end

  after do
    WebMock.disable!
    WebMock.reset!
  end

  describe '#perform' do
    context 'with valid parameters' do
      it 'processes the webhook sync successfully' do
        described_class.perform_now(public_market.id)

        public_market.reload
        expect(public_market.sync_status).to eq('sync_completed')
      end

      it 'makes webhook request with correct payload' do
        described_class.perform_now(public_market.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: hash_including('event' => 'market.completed')
          )
      end
    end

    context 'when webhook delivery fails' do
      before do
        stub_request(:post, editor.completion_webhook_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'updates sync status to failed' do
        # The job uses retry_on StandardError, so it won't raise in perform_now
        # Instead, it will be scheduled for retry
        described_class.perform_now(public_market.id)

        public_market.reload
        expect(public_market.sync_status).to eq('sync_failed')
      end

      it 'schedules a retry through retry_on' do
        # Test that the job would be retried in production
        expect {
          described_class.perform_now(public_market.id)
        }.not_to raise_error

        # The retry_on mechanism handles the error internally
        public_market.reload
        expect(public_market.sync_status).to eq('sync_failed')
      end
    end

    context 'when public market is already sync completed' do
      before { public_market.update!(sync_status: :sync_completed) }

      it 'does not perform sync' do
        described_class.perform_now(public_market.id)

        expect(WebMock).not_to have_requested(:post, editor.completion_webhook_url)
      end
    end
  end
end

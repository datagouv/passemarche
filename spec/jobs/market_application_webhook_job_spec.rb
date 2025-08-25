# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe MarketApplicationWebhookJob, type: :job do
  let(:editor) { create(:editor, completion_webhook_url: 'https://example.com/webhook') }
  let(:public_market) { create(:public_market, editor:, completed_at: Time.zone.now, sync_status: :sync_completed) }
  let(:market_application) { create(:market_application, public_market:, siret: '12345678901234', completed_at: Time.zone.now, sync_status: :sync_processing) }

  before do
    WebMock.enable!
    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 200, body: 'OK')
    allow(SiretValidationService).to receive(:call).and_return(true)
  end

  after do
    WebMock.disable!
    WebMock.reset!
  end

  describe '#perform' do
    context 'with valid parameters' do
      it 'processes the webhook sync successfully' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.sync_status).to eq('sync_completed')
      end

      it 'makes webhook request with correct payload' do
        described_class.perform_now(market_application.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: hash_including('event' => 'market_application.completed')
          )
      end
    end

    context 'when webhook delivery fails' do
      before do
        stub_request(:post, editor.completion_webhook_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'keeps sync status as processing (will retry)' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.sync_status).to eq('sync_processing')
      end
    end

    context 'when public market is already sync completed' do
      before { market_application.update!(sync_status: :sync_completed) }

      it 'does not perform sync' do
        described_class.perform_now(market_application.id)

        expect(WebMock).not_to have_requested(:post, editor.completion_webhook_url)
      end
    end

    context 'when public market does not exist' do
      it 'logs to bug tracker and does not retry' do
        allow(BugTrackerService).to receive(:capture_exception)

        non_existent_id = 999_999
        expect(BugTrackerService).to receive(:capture_exception)
          .with(
            an_instance_of(ActiveRecord::RecordNotFound),
            hash_including(entity_id: non_existent_id, message: /Entity not found/)
          )

        expect {
          described_class.perform_now(non_existent_id)
        }.not_to raise_error
      end
    end
  end
end

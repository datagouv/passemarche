# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe PublicMarketWebhookJob, type: :job do
  let(:editor) { create(:editor, completion_webhook_url: 'https://example.com/webhook') }
  let(:public_market) { create(:public_market, editor:, completed_at: Time.zone.now, sync_status: :sync_processing) }

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

    context 'with lots' do
      let(:market_type) { create(:market_type, code: 'supplies') }
      let(:other_market_type) { create(:market_type, code: 'services') }

      it 'includes lot id, name and effective market_type_code in payload' do
        lot = create(:lot, public_market:, name: 'Lot 1', platform_market_type: market_type)

        described_class.perform_now(public_market.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(body: hash_including(
            'market' => hash_including(
              'lots' => [hash_including('id' => lot.id, 'name' => 'Lot 1', 'market_type_code' => 'supplies')]
            )
          ))
      end

      it 'uses overridden market_type when set' do
        create(:lot, public_market:, platform_market_type: market_type, market_type: other_market_type)

        described_class.perform_now(public_market.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(body: hash_including(
            'market' => hash_including(
              'lots' => [hash_including('market_type_code' => 'services')]
            )
          ))
      end

      it 'includes cpv_code when present' do
        create(:lot, public_market:, cpv_code: '30213100-6', platform_market_type: market_type)

        described_class.perform_now(public_market.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(body: hash_including(
            'market' => hash_including(
              'lots' => [hash_including('cpv_code' => '30213100-6')]
            )
          ))
      end

      it 'includes cpv_code as nil when absent' do
        create(:lot, public_market:, cpv_code: nil, platform_market_type: market_type)

        described_class.perform_now(public_market.id)

        parsed_body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last.body)
        lot_payload = parsed_body['market']['lots'].first
        expect(lot_payload['cpv_code']).to be_nil
      end
    end

    context 'with a configuration summary attached' do
      before do
        public_market.configuration_summary.attach(io: StringIO.new('pdf'), filename: 'summary.pdf', content_type: 'application/pdf')
      end

      it 'includes the configuration summary URL in the payload' do
        described_class.perform_now(public_market.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(body: hash_including(
            'market' => hash_including(
              'configuration_summary_url' => end_with("/api/v1/public_markets/#{public_market.identifier}/configuration_summary")
            )
          ))
      end
    end

    context 'without a configuration summary attached' do
      it 'sets the configuration summary URL to nil' do
        described_class.perform_now(public_market.id)

        parsed_body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last.body)
        expect(parsed_body['market']['configuration_summary_url']).to be_nil
      end
    end

    context 'when webhook delivery fails' do
      before do
        stub_request(:post, editor.completion_webhook_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'keeps sync status as processing (will retry)' do
        described_class.perform_now(public_market.id)

        public_market.reload
        expect(public_market.sync_status).to eq('sync_processing')
      end
    end

    context 'when public market is already sync completed' do
      before { public_market.update!(sync_status: :sync_completed) }

      it 'does not perform sync' do
        described_class.perform_now(public_market.id)

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

        expect do
          described_class.perform_now(non_existent_id)
        end.not_to raise_error
      end
    end
  end
end

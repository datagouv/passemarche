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
    allow(SiretValidator).to receive(:valid?).and_return(true)
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

      it 'includes attestation_url in webhook payload' do
        described_class.perform_now(market_application.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with { |request|
            payload = JSON.parse(request.body)
            expect(payload.dig('market_application', 'attestation_url'))
              .to eq("http://example.com/api/v1/market_applications/#{market_application.identifier}/attestation")
          }
      end

      it 'includes documents_package_url in webhook payload' do
        described_class.perform_now(market_application.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with { |request|
            payload = JSON.parse(request.body)
            expect(payload.dig('market_application', 'documents_package_url'))
              .to eq("http://example.com/api/v1/market_applications/#{market_application.identifier}/documents_package")
          }
      end
    end

    context 'with lots selected by the candidate' do
      let(:market_type) { create(:market_type, code: 'supplies') }
      let(:other_market_type) { create(:market_type, code: 'services') }

      it 'includes only the lots selected by the candidate, distinct from the market lots' do
        selected_lot = create(:lot, public_market:, name: 'Lot 1', platform_market_type: market_type)
        create(:lot, public_market:, name: 'Lot 2', platform_market_type: other_market_type)
        create(:market_application_lot, market_application:, lot: selected_lot)

        described_class.perform_now(market_application.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(body: hash_including(
            'market_application' => hash_including(
              'selected_lots' => [hash_including('id' => selected_lot.id, 'name' => 'Lot 1', 'market_type_code' => 'supplies')]
            )
          ))
      end

      it 'reflects the up to date selection after it has been modified' do
        first_lot = create(:lot, public_market:, name: 'Lot 1', platform_market_type: market_type)
        new_lot = create(:lot, public_market:, name: 'Lot 4', platform_market_type: market_type)
        create(:market_application_lot, market_application:, lot: first_lot)
        market_application.lots = [new_lot]

        described_class.perform_now(market_application.id)

        expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
          .with(body: hash_including(
            'market_application' => hash_including(
              'selected_lots' => [hash_including('id' => new_lot.id, 'name' => 'Lot 4')]
            )
          ))
      end

      it 'sends an empty selected_lots array when the market has no lots' do
        described_class.perform_now(market_application.id)

        parsed_body = JSON.parse(WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last.body)
        expect(parsed_body['market_application']['selected_lots']).to eq([])
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

        expect do
          described_class.perform_now(non_existent_id)
        end.not_to raise_error
      end
    end
  end
end

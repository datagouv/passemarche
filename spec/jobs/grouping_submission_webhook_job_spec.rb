# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GroupingSubmissionWebhookJob, type: :job do
  let(:editor) { create(:editor, completion_webhook_url: 'https://example.com/webhook') }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:grouping) { create(:grouping, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    WebMock.enable!
    stub_request(:post, editor.completion_webhook_url).to_return(status: 200, body: 'OK')

    grouping.mandataire_grouping_member.update!(status: :completed, company_name: 'ACME')
    create(:grouping_member, :co_traitant, grouping:, status: :completed, company_name: 'CO ACME')
    grouping.submit!(mode: :full)
  end

  after do
    WebMock.disable!
    WebMock.reset!
  end

  describe '#perform' do
    it 'processes the webhook sync successfully' do
      described_class.perform_now(grouping.id)

      expect(grouping.reload.sync_status).to eq('sync_completed')
    end

    it 'makes webhook request with correct event and mode' do
      described_class.perform_now(grouping.id)

      expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
        .with(body: hash_including('event' => 'grouping.submitted', 'submission_mode' => 'full'))
    end

    it 'includes every member, mandataire included, in the payload' do
      described_class.perform_now(grouping.id)

      expect(WebMock).to have_requested(:post, editor.completion_webhook_url)
        .with { |request|
          payload = JSON.parse(request.body)
          roles = payload.dig('grouping', 'members').pluck('role')
          expect(roles).to contain_exactly('mandataire', 'co_traitant')
        }
    end

    context 'when webhook delivery fails' do
      before { stub_request(:post, editor.completion_webhook_url).to_return(status: 500, body: 'Internal Server Error') }

      it 'keeps sync status as processing (will retry)' do
        described_class.perform_now(grouping.id)

        expect(grouping.reload.sync_status).to eq('sync_processing')
      end
    end

    context 'when grouping is already sync completed' do
      before { grouping.update!(sync_status: :sync_completed) }

      it 'does not perform sync' do
        described_class.perform_now(grouping.id)

        expect(WebMock).not_to have_requested(:post, editor.completion_webhook_url)
      end
    end

    it 'avoids N+1 queries by eager loading members, applications and lots' do
      create(:grouping_member, :co_traitant, grouping:, status: :completed, company_name: 'CO ACME 2')

      per_member_query_patterns = [
        /SELECT "market_applications"\.\* FROM "market_applications" WHERE "market_applications"\."id" = \$1/,
        /SELECT "lots"\.\* FROM "lots" INNER JOIN "market_application_lots"/
      ]
      occurrences = Hash.new(0)

      counter = lambda { |_name, _started, _finished, _id, payload|
        sql = payload[:sql]
        per_member_query_patterns.each { |pattern| occurrences[pattern] += 1 if sql.match?(pattern) }
      }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        described_class.perform_now(grouping.id)
      end

      expect(occurrences.values).to all(be <= 1)
    end
  end
end

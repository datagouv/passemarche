# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::EnqueueApiDataFetch do
  include ActiveJob::TestHelper

  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }

  before do
    public_market.market_attributes << [
      create(:market_attribute, api_name: 'insee', api_key: 'siret'),
      create(:market_attribute, api_name: 'qualibat', api_key: 'qualibat')
    ]
  end

  describe '.call' do
    context 'when api_fetch_status is empty' do
      before { market_application.update!(api_fetch_status: {}) }

      it 'enqueues FetchApiDataCoordinatorJob for every API to fetch' do
        expect do
          described_class.call(market_application:)
        end.to have_enqueued_job(FetchApiDataCoordinatorJob).with(market_application.id, %w[insee qualibat])
      end

      it 'sets pending status for each API to fetch' do
        described_class.call(market_application:)

        expect(market_application.reload.api_fetch_status.transform_values { |status| status['status'] })
          .to eq('insee' => 'pending', 'qualibat' => 'pending')
      end
    end

    context 'when every API to fetch already has a status' do
      before do
        market_application.update!(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'qualibat' => { 'status' => 'failed' }
        })
      end

      it 'does not enqueue FetchApiDataCoordinatorJob' do
        expect do
          described_class.call(market_application:)
        end.not_to have_enqueued_job(FetchApiDataCoordinatorJob)
      end
    end

    context 'when an API became required after the first fetch' do
      before { market_application.update!(api_fetch_status: { 'insee' => { 'status' => 'completed' } }) }

      it 'only enqueues the missing API' do
        expect do
          described_class.call(market_application:)
        end.to have_enqueued_job(FetchApiDataCoordinatorJob).with(market_application.id, %w[qualibat])
      end

      it 'marks the missing API as pending and keeps the fetched ones' do
        described_class.call(market_application:)

        expect(market_application.reload.api_fetch_status.transform_values { |status| status['status'] })
          .to eq('insee' => 'completed', 'qualibat' => 'pending')
      end
    end
  end
end

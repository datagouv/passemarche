# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::EnqueueApiDataFetch do
  include ActiveJob::TestHelper

  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }

  describe '.call' do
    context 'when api_fetch_status is empty' do
      before { market_application.update!(api_fetch_status: {}) }

      it 'enqueues FetchApiDataCoordinatorJob' do
        expect do
          described_class.call(market_application:)
        end.to have_enqueued_job(FetchApiDataCoordinatorJob).with(market_application.id)
      end

      it 'sets pending status for each API to fetch' do
        described_class.call(market_application:)

        api_names = market_application.api_names_to_fetch
        market_application.reload.api_fetch_status.each do |name, status|
          next unless api_names.include?(name)

          expect(status['status']).to eq('pending')
        end
      end
    end

    context 'when api_fetch_status is already present' do
      before { market_application.update!(api_fetch_status: { 'insee' => { 'status' => 'completed' } }) }

      it 'does not enqueue FetchApiDataCoordinatorJob' do
        expect do
          described_class.call(market_application:)
        end.not_to have_enqueued_job(FetchApiDataCoordinatorJob)
      end
    end
  end
end

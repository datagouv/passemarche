# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchApiDataCoordinatorJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:) }

  describe '#perform' do
    context 'with valid market application' do
      it 'spawns all individual API fetch jobs' do
        expect(FetchInseeDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchRneDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchQualibatDataJob).to receive(:perform_later).with(market_application.id)

        described_class.perform_now(market_application.id)
      end

      it 'spawns jobs for all defined API jobs' do
        # Ensure we test all jobs in the constant
        expect(described_class::API_JOBS.count).to eq(3)
        expect(described_class::API_JOBS)
          .to include(FetchInseeDataJob, FetchRneDataJob, FetchQualibatDataJob)
      end
    end

    context 'when an error occurs spawning jobs' do
      before do
        allow(FetchInseeDataJob)
          .to receive(:perform_later).and_raise(StandardError, 'Queue error')
      end

      it 'logs the error and re-raises' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(market_application.id)
        end.to raise_error(StandardError, 'Queue error')

        expect(Rails.logger).to have_received(:error)
          .with(/Error in coordinator for market application #{market_application.id}: Queue error/)
      end
    end

    context 'when market application does not exist' do
      it 'does not validate existence (delegated to individual jobs)' do
        non_existent_id = 999_999

        # The coordinator doesn't find the market_application
        # Validation happens in individual API jobs
        expect do
          described_class.perform_now(non_existent_id)
        end.not_to raise_error
      end
    end
  end
end

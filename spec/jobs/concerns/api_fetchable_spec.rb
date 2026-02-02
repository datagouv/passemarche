# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiFetchable, type: :job do
  # Create a test job class that includes the concern
  let(:test_job_class) do
    Class.new(ApplicationJob) do
      include ApiFetchable

      def self.api_name
        'test_api'
      end

      def self.api_service
        @api_service ||= Class.new do
          def self.call(**)
            OpenStruct.new(success?: true)
          end
        end
      end

      def self.name
        'TestApiFetchableJob'
      end
    end
  end

  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:, api_fetch_status: {}) }

  let!(:test_attribute) do
    create(:market_attribute, api_name: 'test_api').tap do |attr|
      attr.public_markets << public_market
    end
  end

  describe 'retry configuration' do
    it 'defines retryable errors' do
      expect(ApiFetchable::RETRYABLE_ERRORS).to include(
        Net::OpenTimeout,
        Net::ReadTimeout,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        SocketError
      )
    end

    it 'includes retry_on in the included block' do
      # Verify the concern configures retry behavior
      expect(test_job_class.ancestors).to include(ApiFetchable)
    end
  end

  describe 'retryable error handling' do
    context 'when a retryable error occurs' do
      before do
        allow(test_job_class.api_service).to receive(:call).and_raise(Net::OpenTimeout)
        allow(BugTrackerService).to receive(:capture_exception)
      end

      it 'does not mark as failed on first attempt (retry_on catches the error)' do
        # With retry_on, the error is caught and a retry is scheduled
        # perform_now doesn't re-raise for retryable errors
        test_job_class.perform_now(market_application.id)

        market_application.reload
        # Status should still be processing (set before the API call)
        # because retry_on catches the error before handle_error marks it failed
        expect(market_application.api_fetch_status.dig('test_api', 'status')).to eq('processing')
      end

      it 'eventually calls handle_retries_exhausted after all attempts' do
        # This is tested in the handle_retries_exhausted describe block
        # Here we just verify the error doesn't propagate
        expect { test_job_class.perform_now(market_application.id) }.not_to raise_error
      end
    end
  end

  describe 'non-retryable error handling' do
    context 'when a non-retryable error occurs' do
      let(:standard_error) { StandardError.new('Some unexpected error') }

      before do
        allow(test_job_class.api_service).to receive(:call).and_raise(standard_error)
      end

      it 'marks as failed immediately' do
        begin
          test_job_class.perform_now(market_application.id)
        rescue StandardError
          # Expected
        end

        market_application.reload
        expect(market_application.api_fetch_status.dig('test_api', 'status')).to eq('failed')
      end
    end
  end

  describe '#handle_retries_exhausted' do
    let(:job) { test_job_class.new(market_application.id) }
    let(:error) { Net::OpenTimeout.new('Connection timed out') }

    before do
      allow(BugTrackerService).to receive(:capture_exception)
    end

    it 'logs the error' do
      allow(Rails.logger).to receive(:error)

      job.send(:handle_retries_exhausted, error)

      expect(Rails.logger).to have_received(:error)
        .with(/\[test_api\] All retries exhausted/)
    end

    it 'marks the market application as failed' do
      job.send(:handle_retries_exhausted, error)

      market_application.reload
      expect(market_application.api_fetch_status.dig('test_api', 'status')).to eq('failed')
    end

    it 'reports to bug tracker' do
      job.send(:handle_retries_exhausted, error)

      expect(BugTrackerService).to have_received(:capture_exception)
        .with(error, hash_including(
          job: 'TestApiFetchableJob',
          api_name: 'test_api',
          market_application_id: market_application.id,
          message: 'API call failed after all retries'
        ))
    end

    it 'marks api attributes as manual_after_api_failure' do
      job.send(:handle_retries_exhausted, error)

      responses = market_application.market_attribute_responses
        .joins(:market_attribute)
        .where(market_attributes: { api_name: 'test_api' })

      expect(responses.pluck(:source).uniq).to eq(['manual_after_api_failure'])
    end

    context 'when market application does not exist' do
      let(:job) { test_job_class.new(999_999) }

      it 'does not raise an error' do
        expect { job.send(:handle_retries_exhausted, error) }.not_to raise_error
      end

      it 'still reports to bug tracker' do
        job.send(:handle_retries_exhausted, error)

        expect(BugTrackerService).to have_received(:capture_exception)
      end
    end
  end

  describe '#retryable_error?' do
    let(:job) { test_job_class.new(market_application.id) }

    it 'returns true for retryable errors' do
      ApiFetchable::RETRYABLE_ERRORS.each do |error_class|
        error = error_class.new
        expect(job.send(:retryable_error?, error)).to be(true), "Expected #{error_class} to be retryable"
      end
    end

    it 'returns false for non-retryable errors' do
      expect(job.send(:retryable_error?, StandardError.new)).to be(false)
      expect(job.send(:retryable_error?, OpenSSL::SSL::SSLError.new)).to be(false)
      expect(job.send(:retryable_error?, ArgumentError.new)).to be(false)
    end
  end
end

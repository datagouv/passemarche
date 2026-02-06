# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationStepUpdateService do
  include ApiResponses::InseeResponses
  include ApiResponses::RneResponses

  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:, siret: '41816609600069') }
  let(:token) { 'test_token_123' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(base_url:, token:)
    )
  end

  describe '.call' do
    context 'with company_identification step' do
      it 'returns success' do
        result = described_class.call(market_application, :company_identification, {})

        expect(result[:success]).to be true
      end

      it 'does not modify SIRET (SIRET is locked)' do
        original_siret = market_application.siret

        described_class.call(market_application, :company_identification, {})

        expect(market_application.reload.siret).to eq(original_siret)
      end

      it 'does not call APIs directly' do
        expect(Insee).not_to receive(:call)
        expect(Rne).not_to receive(:call)

        described_class.call(market_application, :company_identification, {})
      end

      it 'has no flash messages' do
        result = described_class.call(market_application, :company_identification, {})

        expect(result[:flash_messages]).to be_empty
      end

      it 'enqueues API data fetch job when api_fetch_status is empty' do
        market_application.update!(api_fetch_status: {})

        expect(FetchApiDataCoordinatorJob).to receive(:perform_later).with(market_application.id)

        described_class.call(market_application, :company_identification, {})
      end

      it 'does not enqueue API data fetch job when api_fetch_status is present' do
        market_application.update!(api_fetch_status: { 'insee' => { 'status' => 'completed' } })

        expect(FetchApiDataCoordinatorJob).not_to receive(:perform_later)

        described_class.call(market_application, :company_identification, {})
      end
    end

    context 'with api_data_recovery_status step' do
      let(:params) { {} }

      it 'returns success' do
        result = described_class.call(market_application, :api_data_recovery_status, params)

        expect(result[:success]).to be true
      end

      it 'has no flash messages' do
        result = described_class.call(market_application, :api_data_recovery_status, params)

        expect(result[:flash_messages]).to be_empty
      end

      it 'is a simple passthrough (API calls happen in background jobs)' do
        # This step doesn't trigger API calls directly anymore
        # API calls are triggered via background jobs in company_identification step
        result = described_class.call(market_application, :api_data_recovery_status, params)

        expect(result[:success]).to be true
        expect(result[:market_application]).to eq(market_application)
      end
    end

    context 'with generic step' do
      let(:step) { :contact }

      it 'returns success when validation passes' do
        result = described_class.call(market_application, step, {})

        expect(result[:success]).to be true
      end

      it 'reloads responses after save' do
        expect(market_application.market_attribute_responses).to receive(:reload)

        described_class.call(market_application, step, {})
      end
    end

    context 'with summary step' do
      before do
        allow(CompleteMarketApplication).to receive(:call)
          .and_return(double(success?: true))
      end

      it 'calls CompleteMarketApplication organizer' do
        expect(CompleteMarketApplication).to receive(:call)
          .with(market_application:)

        described_class.call(market_application, :summary, {})
      end

      it 'returns success with redirect' do
        result = described_class.call(market_application, :summary, {})

        expect(result[:success]).to be true
        expect(result[:redirect]).to eq(:sync_status)
      end

      context 'when completion fails' do
        before do
          allow(CompleteMarketApplication).to receive(:call)
            .and_return(double(success?: false, message: 'Completion error'))
        end

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end

        it 'includes error message in flash' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:flash_messages][:alert]).to eq('Completion error')
        end
      end

      context 'when an exception occurs' do
        before do
          allow(CompleteMarketApplication).to receive(:call)
            .and_raise(ActiveRecord::RecordInvalid.new(market_application))
        end

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error)
            .with(/Error completing market application/)

          described_class.call(market_application, :summary, {})
        end

        it 'includes generic error message in flash' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:flash_messages][:alert]).to be_present
        end
      end
    end
  end
end

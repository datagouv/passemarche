# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchProbtpDataJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:, api_fetch_status: {}) }

  let!(:probtp_attribute) do
    create(:market_attribute, api_name: 'probtp').tap do |attr|
      attr.public_markets << public_market
    end
  end

  describe '.api_name' do
    it 'returns the correct API name' do
      expect(described_class.api_name).to eq('probtp')
    end
  end

  describe '.api_service' do
    it 'returns the Probtp organizer' do
      expect(described_class.api_service).to eq(Probtp)
    end
  end

  describe '#perform' do
    context 'when API call is successful' do
      let(:successful_result) { double('Result', success?: true) }

      before do
        allow(Probtp).to receive(:call).and_return(successful_result)
      end

      it 'updates status to processing before API call' do
        allow(market_application).to receive(:update_api_status).and_call_original
        allow(MarketApplication).to receive(:find).and_return(market_application)

        described_class.perform_now(market_application.id)

        expect(market_application).to have_received(:update_api_status)
          .with('probtp', status: 'processing').ordered
      end

      it 'calls the Probtp organizer with correct parameters' do
        described_class.perform_now(market_application.id)

        expect(Probtp).to have_received(:call).with(
          params: { siret: },
          market_application:
        )
      end

      it 'updates status to completed after successful API call' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.api_fetch_status['probtp']['status']).to eq('completed')
      end
    end

    context 'when API call fails' do
      let(:failed_result) { double('Result', success?: false) }

      before do
        allow(Probtp).to receive(:call).and_return(failed_result)
      end

      it 'updates status to failed' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.api_fetch_status['probtp']['status']).to eq('failed')
      end

      it 'marks API attributes as manual_after_api_failure' do
        described_class.perform_now(market_application.id)

        responses = market_application.market_attribute_responses
          .joins(:market_attribute)
          .where(market_attributes: { api_name: 'probtp' })

        expect(responses.count).to eq(1)
        expect(responses.pluck(:source).uniq).to eq(['manual_after_api_failure'])
      end
    end

    context 'when an exception occurs' do
      before do
        allow(Probtp).to receive(:call).and_raise(Faraday::Error, 'Network error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error, updates status to failed, and re-raises' do
        expect do
          described_class.perform_now(market_application.id)
        end.to raise_error(Faraday::Error, 'Network error')

        expect(Rails.logger).to have_received(:error)
          .with(/Error fetching probtp data/)

        market_application.reload
        expect(market_application.api_fetch_status['probtp']['status']).to eq('failed')
      end
    end
  end
end

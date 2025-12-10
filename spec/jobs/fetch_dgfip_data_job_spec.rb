# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchDgfipDataJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:, api_fetch_status: {}) }

  let!(:dgfip_attribute_1) do
    create(:market_attribute, api_name: 'attestations_fiscales').tap do |attr|
      attr.public_markets << public_market
    end
  end
  let!(:dgfip_attribute_2) do
    create(:market_attribute, api_name: 'attestations_fiscales').tap do |attr|
      attr.public_markets << public_market
    end
  end

  describe '.api_name' do
    it 'returns the correct API name' do
      expect(described_class.api_name).to eq('attestations_fiscales')
    end
  end

  describe '.api_service' do
    it 'returns the Dgfip organizer' do
      expect(described_class.api_service).to eq(Dgfip)
    end
  end

  describe '#perform' do
    context 'when API call is successful' do
      let(:successful_result) { double('Result', success?: true) }

      before do
        allow(Dgfip).to receive(:call).and_return(successful_result)
      end

      it 'updates status to processing before API call' do
        allow(market_application).to receive(:update_api_status).and_call_original
        allow(MarketApplication).to receive(:find).and_return(market_application)

        described_class.perform_now(market_application.id)

        expect(market_application).to have_received(:update_api_status)
          .with('attestations_fiscales', status: 'processing').ordered
      end

      it 'calls the Dgfip organizer with correct parameters' do
        described_class.perform_now(market_application.id)

        expect(Dgfip).to have_received(:call).with(
          params: { siret: },
          market_application:
        )
      end

      it 'updates status to completed after successful API call' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.api_fetch_status['attestations_fiscales']['status']).to eq('completed')
      end

      it 'counts filled fields correctly' do
        create(:market_attribute_response,
          market_application:,
          market_attribute: dgfip_attribute_1,
          source: :auto)
        create(:market_attribute_response,
          market_application:,
          market_attribute: dgfip_attribute_2,
          source: :auto)

        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.api_fetch_status['attestations_fiscales']['fields_filled']).to eq(2)
      end

      it 'records the timestamp of the update' do
        freeze_time do
          described_class.perform_now(market_application.id)

          market_application.reload
          expect(market_application.api_fetch_status['attestations_fiscales']['updated_at'])
            .to eq(Time.current.iso8601)
        end
      end
    end

    context 'when API call fails' do
      let(:failed_result) { double('Result', success?: false) }

      before do
        allow(Dgfip).to receive(:call).and_return(failed_result)
      end

      it 'updates status to failed' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.api_fetch_status['attestations_fiscales']['status']).to eq('failed')
      end

      it 'sets fields_filled to 0' do
        described_class.perform_now(market_application.id)

        market_application.reload
        expect(market_application.api_fetch_status['attestations_fiscales']['fields_filled']).to eq(0)
      end

      it 'marks API attributes as manual_after_api_failure' do
        described_class.perform_now(market_application.id)

        responses = market_application.market_attribute_responses
          .joins(:market_attribute)
          .where(market_attributes: { api_name: 'attestations_fiscales' })

        expect(responses.count).to eq(2)
        expect(responses.pluck(:source).uniq).to eq(['manual_after_api_failure'])
      end

      it 'does not mark already manual_after_api_failure responses' do
        existing_response = create(:market_attribute_response,
          market_application:,
          market_attribute: dgfip_attribute_1,
          source: :manual_after_api_failure,
          value: 'existing value')

        described_class.perform_now(market_application.id)

        expect(existing_response.reload.value).to eq('existing value')
      end
    end

    context 'when an error occurs during API call' do
      let(:error_message) { 'API timeout error' }

      before do
        allow(Dgfip).to receive(:call).and_raise(StandardError, error_message)
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(market_application.id)
        end.to raise_error(StandardError, error_message)

        expect(Rails.logger).to have_received(:error)
          .with(/Error fetching attestations_fiscales data for #{market_application.id}/)
      end

      it 'updates status to failed' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(market_application.id)
        end.to raise_error(StandardError)

        market_application.reload
        expect(market_application.api_fetch_status['attestations_fiscales']['status']).to eq('failed')
      end

      it 're-raises the error for retry mechanism' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(market_application.id)
        end.to raise_error(StandardError, error_message)
      end
    end

    context 'when market application does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        non_existent_id = 999_999

        expect do
          described_class.perform_now(non_existent_id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

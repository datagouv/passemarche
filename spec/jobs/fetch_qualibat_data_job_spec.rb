# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchQualibatDataJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '78824266700020' }
  let(:market_application) { create(:market_application, public_market:, siret:) }

  describe '.api_name' do
    it 'returns qualibat' do
      expect(described_class.api_name).to eq('qualibat')
    end
  end

  describe '.api_service' do
    it 'returns Qualibat' do
      expect(described_class.api_service).to eq(Qualibat)
    end
  end

  describe '#perform' do
    context 'when Qualibat API succeeds' do
      it 'calls the Qualibat organizer with the correct parameters' do
        expect(Qualibat).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: true))

        described_class.new.perform(market_application.id)
      end
    end

    context 'when Qualibat API fails' do
      it 'handles API failures gracefully' do
        expect(Qualibat).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: false, error: 'API Error'))

        expect { described_class.new.perform(market_application.id) }.not_to raise_error
      end
    end

    context 'when Qualibat API times out' do
      it 'handles timeout errors gracefully' do
        expect(Qualibat).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: false, error: 'Timeout'))

        expect { described_class.new.perform(market_application.id) }.not_to raise_error
      end
    end

    context 'when market_application does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.new.perform(999_999) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

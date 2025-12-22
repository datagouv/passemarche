# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchBodaccDataJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:) }

  describe '.api_name' do
    it 'returns bodacc' do
      expect(described_class.api_name).to eq('bodacc')
    end
  end

  describe '.api_service' do
    it 'returns Bodacc' do
      expect(described_class.api_service).to eq(Bodacc)
    end
  end

  describe '#perform' do
    context 'when Bodacc API succeeds' do
      it 'calls the Bodacc organizer with the correct parameters' do
        expect(Bodacc).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: true))

        described_class.perform_now(market_application.id)
      end
    end

    context 'when Bodacc API fails' do
      it 'calls the Bodacc organizer and handles failure gracefully' do
        expect(Bodacc).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: false))

        expect { described_class.perform_now(market_application.id) }.not_to raise_error
      end
    end
  end
end

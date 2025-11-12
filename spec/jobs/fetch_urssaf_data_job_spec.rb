# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchUrssafDataJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:) }

  describe '.api_name' do
    it 'returns urssaf_attestation_vigilance' do
      expect(described_class.api_name).to eq('urssaf_attestation_vigilance')
    end
  end

  describe '.api_service' do
    it 'returns Urssaf' do
      expect(described_class.api_service).to eq(Urssaf)
    end
  end

  describe '#perform' do
    context 'when URSSAF API succeeds' do
      it 'calls the Urssaf organizer with the correct parameters' do
        expect(Urssaf).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: true))

        described_class.perform_now(market_application.id)
      end
    end

    context 'when URSSAF API fails' do
      it 'calls the Urssaf organizer and handles failure gracefully' do
        expect(Urssaf).to receive(:call).with(
          params: { siret: },
          market_application:
        ).and_return(double(success?: false))

        expect { described_class.perform_now(market_application.id) }.not_to raise_error
      end
    end

    context 'when market application has no SIRET' do
      let(:market_application) { create(:market_application, public_market:, siret: nil) }

      it 'exits early without calling the API' do
        expect(Urssaf).not_to receive(:call)

        described_class.perform_now(market_application.id)
      end
    end
  end
end

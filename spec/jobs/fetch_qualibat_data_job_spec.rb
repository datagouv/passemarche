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
    it 'calls the Qualibat organizer with the correct parameters' do
      expect(Qualibat).to receive(:call).with(
        params: { siret: },
        market_application:
      ).and_return(double(success?: true))

      described_class.new.perform(market_application.id)
    end
  end
end

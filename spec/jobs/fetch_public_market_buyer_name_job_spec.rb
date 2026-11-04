# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchPublicMarketBuyerNameJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }

  def mock_result(success:, social_reason: nil)
    bundled_data = success ? double(data: double(social_reason:)) : nil
    double(success?: success, bundled_data:)
  end

  describe '#perform' do
    context 'when Insee succeeds with a buyer name' do
      before do
        allow(Insee).to receive(:call).and_return(mock_result(success: true, social_reason: 'Ville de Paris'))
      end

      it 'calls Insee with the public market siret and object' do
        expect(Insee).to receive(:call).with(params: { siret: public_market.siret }, public_market:)
        described_class.perform_now(public_market.id)
      end

      it 'updates buyer_name on the public market' do
        described_class.perform_now(public_market.id)
        expect(public_market.reload.buyer_name).to eq('Ville de Paris')
      end
    end

    context 'when Insee succeeds with a blank buyer name' do
      before do
        allow(Insee).to receive(:call).and_return(mock_result(success: true, social_reason: nil))
      end

      it 'does not update buyer_name' do
        described_class.perform_now(public_market.id)
        expect(public_market.reload.buyer_name).to be_nil
      end
    end

    context 'when Insee fails' do
      before do
        allow(Insee).to receive(:call).and_return(mock_result(success: false))
      end

      it 'does not update buyer_name' do
        described_class.perform_now(public_market.id)
        expect(public_market.reload.buyer_name).to be_nil
      end
    end

    context 'when the public market does not exist' do
      it 'discards the job without raising' do
        expect { described_class.perform_now(-1) }.not_to raise_error
      end
    end
  end
end

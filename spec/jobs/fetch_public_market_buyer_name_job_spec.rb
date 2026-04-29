# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchPublicMarketBuyerNameJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }

  describe '#perform' do
    context 'when FetchBuyerName succeeds with a buyer name' do
      before do
        allow(FetchBuyerName).to receive(:call).and_return(
          double(success?: true, buyer_name: 'Ville de Paris')
        )
      end

      it 'calls FetchBuyerName with the public_market' do
        expect(FetchBuyerName).to receive(:call).with(public_market:)
        described_class.perform_now(public_market.id)
      end

      it 'updates buyer_name on the public market' do
        described_class.perform_now(public_market.id)
        expect(public_market.reload.buyer_name).to eq('Ville de Paris')
      end
    end

    context 'when FetchBuyerName succeeds with a blank buyer name' do
      before do
        allow(FetchBuyerName).to receive(:call).and_return(
          double(success?: true, buyer_name: nil)
        )
      end

      it 'does not update buyer_name' do
        described_class.perform_now(public_market.id)
        expect(public_market.reload.buyer_name).to be_nil
      end
    end

    context 'when FetchBuyerName fails' do
      before do
        allow(FetchBuyerName).to receive(:call).and_return(
          double(success?: false, buyer_name: nil)
        )
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

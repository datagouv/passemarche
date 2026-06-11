# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Buyer::Lots', type: :request do
  let(:editor) { create(:editor) }
  let(:works_type) { create(:market_type, code: 'works') }
  let(:services_type) { create(:market_type, code: 'services') }
  let(:public_market) { create(:public_market, editor:, market_type_codes: [works_type.code]) }
  let!(:lot1) { create(:lot, public_market:, platform_market_type: works_type) }
  let!(:lot2) { create(:lot, public_market:, platform_market_type: works_type) }

  describe 'PATCH /buyer/public_markets/:identifier/lots' do
    context 'when applying a new type to selected lots' do
      it 'updates market_type_id on selected lots' do
        patch buyer_lot_types_path(public_market.identifier),
          params: { lot_ids: [lot1.id, lot2.id], market_type_id: services_type.id },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(lot1.reload.market_type).to eq(services_type)
        expect(lot2.reload.market_type).to eq(services_type)
      end

      it 'returns a turbo stream response' do
        patch buyer_lot_types_path(public_market.identifier),
          params: { lot_ids: [lot1.id], market_type_id: services_type.id },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end

      it 'only updates lots belonging to the public market' do
        other_market = create(:public_market, editor:, market_type_codes: [works_type.code])
        other_lot = create(:lot, public_market: other_market)

        patch buyer_lot_types_path(public_market.identifier),
          params: { lot_ids: [other_lot.id], market_type_id: services_type.id },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(other_lot.reload.market_type).to be_nil
      end
    end

    context 'when the market is completed' do
      let(:public_market) { create(:public_market, :completed, editor:, market_type_codes: [works_type.code]) }

      it 'returns unprocessable entity' do
        patch buyer_lot_types_path(public_market.identifier),
          params: { lot_ids: [lot1.id], market_type_id: services_type.id },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when market_type_id is unknown' do
      it 'sets market_type to nil on selected lots' do
        lot1.update!(market_type: services_type)

        patch buyer_lot_types_path(public_market.identifier),
          params: { lot_ids: [lot1.id], market_type_id: 0 },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(lot1.reload.market_type).to be_nil
      end
    end
  end
end

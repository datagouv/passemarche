# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Buyer::PublicMarkets', type: :request do
  let(:editor) { create(:editor) }
  let(:supplies_type) { create(:market_type, code: 'supplies') }
  let(:services_type) { create(:market_type, code: 'services') }
  let(:defense_type) { create(:market_type, code: 'defense') }

  let!(:required_attr_1) { create(:market_attribute, key: 'req_attr_1', required: true) }
  let!(:required_attr_2) { create(:market_attribute, key: 'req_attr_2', required: true) }
  let!(:optional_attr_1) { create(:market_attribute, key: 'opt_attr_1', required: false) }
  let!(:optional_attr_2) { create(:market_attribute, key: 'opt_attr_2', required: false) }

  before do
    supplies_type.market_attributes << [required_attr_1, optional_attr_1]
    services_type.market_attributes << [required_attr_2, optional_attr_2]
  end

  let(:public_market) do
    create(:public_market,
      editor: editor,
      market_type_codes: [supplies_type.code, services_type.code])
  end

  describe 'PATCH /buyer/public_markets/:identifier/required_fields' do
    context 'when updating from required_fields step' do
      it 'adds all required attributes from associated market types' do
        expect(public_market.market_attributes).to be_empty

        patch "/buyer/public_markets/#{public_market.identifier}/required_fields"

        public_market.reload
        expect(public_market.market_attributes).to include(required_attr_1, required_attr_2)
        expect(public_market.market_attributes).not_to include(optional_attr_1, optional_attr_2)
      end

      it 'redirects to additional_fields step' do
        patch "/buyer/public_markets/#{public_market.identifier}/required_fields"

        expect(response).to redirect_to("/buyer/public_markets/#{public_market.identifier}/additional_fields")
      end

      it 'removes duplicates when market types share attributes' do
        services_type.market_attributes << required_attr_1

        patch "/buyer/public_markets/#{public_market.identifier}/required_fields"

        public_market.reload
        expect(public_market.market_attributes).to include(required_attr_1, required_attr_2)
        attribute_ids = public_market.market_attributes.pluck(:id)
        expect(attribute_ids).to eq(attribute_ids.uniq)
      end
    end
  end

  describe 'PATCH /buyer/public_markets/:identifier/additional_fields' do
    context 'when updating from additional_fields step' do
      before do
        public_market.market_attributes = [required_attr_1, required_attr_2]
        public_market.save!
      end

      it 'adds selected optional attributes while keeping required ones' do
        patch "/buyer/public_markets/#{public_market.identifier}/additional_fields",
          params: { selected_attribute_keys: [optional_attr_1.key] }

        public_market.reload
        expect(public_market.market_attributes).to include(required_attr_1, required_attr_2, optional_attr_1)
        expect(public_market.market_attributes).not_to include(optional_attr_2)
      end

      it 'keeps required attributes even when no optional ones are selected' do
        patch "/buyer/public_markets/#{public_market.identifier}/additional_fields",
          params: { selected_attribute_keys: [] }

        public_market.reload
        expect(public_market.market_attributes).to include(required_attr_1, required_attr_2)
        expect(public_market.market_attributes.count).to eq(2)
      end

      it 'redirects to summary step' do
        patch "/buyer/public_markets/#{public_market.identifier}/additional_fields"

        expect(response).to redirect_to("/buyer/public_markets/#{public_market.identifier}/summary")
      end
    end
  end

  describe 'GET /buyer/public_markets/:identifier/required_fields' do
    it 'displays the required fields page' do
      get "/buyer/public_markets/#{public_market.identifier}/required_fields"

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /buyer/public_markets/:identifier/additional_fields' do
    it 'displays the additional fields page' do
      get "/buyer/public_markets/#{public_market.identifier}/additional_fields"

      expect(response).to have_http_status(:success)
    end
  end
end

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

  describe 'PATCH /buyer/public_markets/:identifier/summary (completion)' do
    let(:summary_path) { step_buyer_public_market_path(public_market.identifier, :summary) }

    context 'when completing the wizard' do
      before do
        patch summary_path
      end

      it 'redirects to sync status page' do
        expect(response).to redirect_to(buyer_sync_status_path(public_market.identifier))
      end

      it 'completes the market' do
        public_market.reload
        expect(public_market).to be_completed
      end

      it 'enqueues webhook sync job' do
        expect(PublicMarketWebhookJob).to have_been_enqueued.with(public_market.id)
      end
    end
  end

  describe 'Access Control & Data Integrity' do
    let(:completed_market) do
      create(:public_market, :completed,
        editor: editor,
        market_type_codes: [supplies_type.code],
        sync_status: :sync_completed)
    end

    shared_examples 'redirects completed market with alert' do |step_name|
      it "redirects to sync status page from #{step_name} step" do
        expect(response).to redirect_to(buyer_sync_status_path(completed_market.identifier))
      end

      it "sets alert message for #{step_name} step" do
        expect(flash[:alert]).to eq(I18n.t('buyer.public_markets.market_completed_cannot_edit'))
      end
    end

    describe 'GET requests to wizard steps for completed markets' do
      context 'when accessing setup step' do
        before { get "/buyer/public_markets/#{completed_market.identifier}/setup" }
        include_examples 'redirects completed market with alert', 'setup'
      end

      context 'when accessing required_fields step' do
        before { get "/buyer/public_markets/#{completed_market.identifier}/required_fields" }
        include_examples 'redirects completed market with alert', 'required_fields'
      end

      context 'when accessing additional_fields step' do
        before { get "/buyer/public_markets/#{completed_market.identifier}/additional_fields" }
        include_examples 'redirects completed market with alert', 'additional_fields'
      end

      context 'when accessing summary step' do
        before { get "/buyer/public_markets/#{completed_market.identifier}/summary" }
        include_examples 'redirects completed market with alert', 'summary'
      end
    end

    describe 'PATCH requests to wizard steps for completed markets' do
      context 'when updating setup step' do
        before { patch "/buyer/public_markets/#{completed_market.identifier}/setup" }
        include_examples 'redirects completed market with alert', 'setup'
      end

      context 'when updating required_fields step' do
        before { patch "/buyer/public_markets/#{completed_market.identifier}/required_fields" }
        include_examples 'redirects completed market with alert', 'required_fields'
      end

      context 'when updating additional_fields step' do
        before do
          patch "/buyer/public_markets/#{completed_market.identifier}/additional_fields",
            params: { selected_attribute_keys: [optional_attr_1.key] }
        end
        include_examples 'redirects completed market with alert', 'additional_fields'
      end

      context 'when trying to complete already completed market' do
        before { patch "/buyer/public_markets/#{completed_market.identifier}/summary" }
        include_examples 'redirects completed market with alert', 'summary'
      end
    end

    describe 'state preservation for completed markets' do
      let(:original_attributes) { completed_market.market_attributes.pluck(:key) }

      it 'does not modify market attributes when accessing required_fields' do
        patch "/buyer/public_markets/#{completed_market.identifier}/required_fields"

        completed_market.reload
        expect(completed_market.market_attributes.pluck(:key)).to eq(original_attributes)
      end

      it 'does not modify market attributes when accessing additional_fields' do
        patch "/buyer/public_markets/#{completed_market.identifier}/additional_fields",
          params: { selected_attribute_keys: [optional_attr_2.key] }

        completed_market.reload
        expect(completed_market.market_attributes.pluck(:key)).to eq(original_attributes)
      end

      it 'preserves completion status and timestamps' do
        original_completed_at = completed_market.completed_at

        patch "/buyer/public_markets/#{completed_market.identifier}/summary"

        completed_market.reload
        expect(completed_market.completed_at).to eq(original_completed_at)
        expect(completed_market).to be_completed
      end
    end

    describe 'non-completed markets still work normally' do
      let(:non_completed_market) do
        create(:public_market,
          editor: editor,
          market_type_codes: [supplies_type.code],
          completed_at: nil)
      end

      it 'allows access to wizard steps for non-completed markets' do
        get "/buyer/public_markets/#{non_completed_market.identifier}/setup"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{non_completed_market.identifier}/required_fields"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{non_completed_market.identifier}/additional_fields"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{non_completed_market.identifier}/summary"
        expect(response).to have_http_status(:success)
      end

      it 'allows updates to wizard steps for non-completed markets' do
        patch "/buyer/public_markets/#{non_completed_market.identifier}/required_fields"
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/buyer/public_markets/#{non_completed_market.identifier}/additional_fields")

        patch "/buyer/public_markets/#{non_completed_market.identifier}/additional_fields"
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/buyer/public_markets/#{non_completed_market.identifier}/summary")
      end
    end
  end
end

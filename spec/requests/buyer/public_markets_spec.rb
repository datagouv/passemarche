# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Buyer::PublicMarkets', type: :request do
  let(:editor) { create(:editor) }
  let(:supplies_type) { create(:market_type, code: 'supplies') }
  let(:services_type) { create(:market_type, code: 'services') }
  let(:defense_type) { create(:market_type, code: 'defense') }

  let!(:mandatory_attr_1) do
    create(:market_attribute, key: 'mand_attr_1', mandatory: true,
      category_key: 'test_category_1', subcategory_key: 'sub1')
  end
  let!(:mandatory_attr_2) do
    create(:market_attribute, key: 'mand_attr_2', mandatory: true,
      category_key: 'test_category_2', subcategory_key: 'sub2')
  end
  let!(:optional_attr_1) do
    create(:market_attribute, key: 'opt_attr_1', mandatory: false,
      category_key: 'test_category_1', subcategory_key: 'sub1')
  end
  let!(:optional_attr_2) do
    create(:market_attribute, key: 'opt_attr_2', mandatory: false,
      category_key: 'test_category_2', subcategory_key: 'sub2')
  end

  before do
    supplies_type.market_attributes << [mandatory_attr_1, optional_attr_1]
    services_type.market_attributes << [mandatory_attr_2, optional_attr_2]
  end

  let(:public_market) do
    create(:public_market,
      editor:,
      market_type_codes: [supplies_type.code, services_type.code])
  end

  describe 'PATCH /buyer/public_markets/:identifier/setup' do
    context 'when updating from setup step' do
      it 'adds all mandatory attributes from associated market types' do
        expect(public_market.market_attributes).to be_empty

        patch "/buyer/public_markets/#{public_market.identifier}/setup"

        public_market.reload
        expect(public_market.market_attributes).to include(mandatory_attr_1, mandatory_attr_2)
        expect(public_market.market_attributes).not_to include(optional_attr_1, optional_attr_2)
      end

      it 'redirects to first category step' do
        patch "/buyer/public_markets/#{public_market.identifier}/setup"

        expect(response).to have_http_status(:redirect)
      end

      it 'removes duplicates when market types share attributes' do
        services_type.market_attributes << mandatory_attr_1

        patch "/buyer/public_markets/#{public_market.identifier}/setup"

        public_market.reload
        expect(public_market.market_attributes).to include(mandatory_attr_1, mandatory_attr_2)
        attribute_ids = public_market.market_attributes.pluck(:id)
        expect(attribute_ids).to eq(attribute_ids.uniq)
      end
    end
  end

  describe 'PATCH /buyer/public_markets/:identifier/:category_step' do
    let(:first_category) do
      presenter = PublicMarketPresenter.new(public_market)
      presenter.wizard_steps[1]
    end

    context 'when updating from a category step' do
      before do
        # First run setup to snapshot required attributes
        patch "/buyer/public_markets/#{public_market.identifier}/setup"
        public_market.reload
      end

      it 'adds selected optional attributes while keeping mandatory ones' do
        patch "/buyer/public_markets/#{public_market.identifier}/#{first_category}",
          params: { selected_attribute_keys: [optional_attr_1.key] }

        public_market.reload
        expect(public_market.market_attributes).to include(mandatory_attr_1, mandatory_attr_2)
      end

      it 'keeps mandatory attributes even when no optional ones are selected' do
        patch "/buyer/public_markets/#{public_market.identifier}/#{first_category}",
          params: { selected_attribute_keys: [] }

        public_market.reload
        expect(public_market.market_attributes).to include(mandatory_attr_1, mandatory_attr_2)
      end

      it 'redirects to next step' do
        patch "/buyer/public_markets/#{public_market.identifier}/#{first_category}"

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'GET /buyer/public_markets/:identifier/:category_step' do
    let(:first_category) do
      presenter = PublicMarketPresenter.new(public_market)
      presenter.wizard_steps[1]
    end

    it 'displays the category step page' do
      get "/buyer/public_markets/#{public_market.identifier}/#{first_category}"

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
        editor:,
        market_type_codes: [supplies_type.code],
        sync_status: :sync_completed)
    end

    let(:first_category) do
      presenter = PublicMarketPresenter.new(completed_market)
      presenter.wizard_steps[1]
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

      context 'when accessing a category step' do
        before { get "/buyer/public_markets/#{completed_market.identifier}/#{first_category}" }
        include_examples 'redirects completed market with alert', 'category'
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

      context 'when updating a category step' do
        before do
          patch "/buyer/public_markets/#{completed_market.identifier}/#{first_category}",
            params: { selected_attribute_keys: [optional_attr_1.key] }
        end
        include_examples 'redirects completed market with alert', 'category'
      end

      context 'when trying to complete already completed market' do
        before { patch "/buyer/public_markets/#{completed_market.identifier}/summary" }
        include_examples 'redirects completed market with alert', 'summary'
      end
    end

    describe 'state preservation for completed markets' do
      let(:original_attributes) { completed_market.market_attributes.pluck(:key) }

      it 'does not modify market attributes when accessing category step' do
        patch "/buyer/public_markets/#{completed_market.identifier}/#{first_category}"

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
          editor:,
          market_type_codes: [supplies_type.code],
          completed_at: nil)
      end

      let(:non_completed_first_category) do
        presenter = PublicMarketPresenter.new(non_completed_market)
        presenter.wizard_steps[1]
      end

      it 'allows access to wizard steps for non-completed markets' do
        get "/buyer/public_markets/#{non_completed_market.identifier}/setup"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{non_completed_market.identifier}/#{non_completed_first_category}"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{non_completed_market.identifier}/summary"
        expect(response).to have_http_status(:success)
      end

      it 'allows updates to wizard steps for non-completed markets' do
        patch "/buyer/public_markets/#{non_completed_market.identifier}/setup"
        expect(response).to have_http_status(:redirect)

        patch "/buyer/public_markets/#{non_completed_market.identifier}/#{non_completed_first_category}"
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end

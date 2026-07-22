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
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end

  let(:public_market) do
    create(:public_market,
      editor:,
      market_type_codes: [supplies_type.code, services_type.code])
  end

  describe 'versioning author' do
    let(:public_market) do
      create(:public_market, :with_provider_user_id,
        editor:,
        market_type_codes: [supplies_type.code, services_type.code])
    end

    before { create(:lot, public_market:) }

    it 'records the market provider_user_id as the version author' do
      patch "/buyer/public_markets/#{public_market.identifier}/lot_config",
        params: { lot_limit_enabled: 'true', lot_limit: '1' }

      public_market.reload
      expect(public_market.versions.last.whodunnit).to eq('editor-user-123')
    end
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

      it 'enqueues configuration summary PDF generation job' do
        expect(GeneratePublicMarketConfigurationSummaryPdfJob).to have_been_enqueued.with(
          public_market.id, request_host: 'www.example.com', request_protocol: 'http://'
        )
      end
    end
  end

  describe 'Access Control & Data Integrity' do
    let(:published_market) do
      create(:public_market, :published,
        editor:,
        market_type_codes: [supplies_type.code])
    end

    let(:first_category) do
      presenter = PublicMarketPresenter.new(published_market)
      presenter.wizard_steps[1]
    end

    shared_examples 'redirects published market' do |step_name|
      it "redirects to published page from #{step_name} step" do
        expect(response).to redirect_to(buyer_published_path(published_market.identifier))
      end
    end

    describe 'GET requests to wizard steps for published markets' do
      context 'when accessing setup step' do
        before { get "/buyer/public_markets/#{published_market.identifier}/setup" }
        include_examples 'redirects published market', 'setup'
      end

      context 'when accessing a category step' do
        before { get "/buyer/public_markets/#{published_market.identifier}/#{first_category}" }
        include_examples 'redirects published market', 'category'
      end

      context 'when accessing summary step' do
        before { get "/buyer/public_markets/#{published_market.identifier}/summary" }
        include_examples 'redirects published market', 'summary'
      end
    end

    describe 'PATCH requests to wizard steps for published markets' do
      context 'when updating setup step' do
        before { patch "/buyer/public_markets/#{published_market.identifier}/setup" }
        include_examples 'redirects published market', 'setup'
      end

      context 'when updating a category step' do
        before do
          patch "/buyer/public_markets/#{published_market.identifier}/#{first_category}",
            params: { selected_attribute_keys: [optional_attr_1.key] }
        end
        include_examples 'redirects published market', 'category'
      end

      context 'when trying to update summary of published market' do
        before { patch "/buyer/public_markets/#{published_market.identifier}/summary" }
        include_examples 'redirects published market', 'summary'
      end
    end

    describe 'completed but non-published markets allow re-entry' do
      let(:completed_market) do
        create(:public_market, :completed,
          editor:,
          market_type_codes: [supplies_type.code])
      end

      let(:completed_first_category) do
        presenter = PublicMarketPresenter.new(completed_market)
        presenter.wizard_steps[1]
      end

      it 'allows access to wizard steps' do
        get "/buyer/public_markets/#{completed_market.identifier}/setup"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{completed_market.identifier}/#{completed_first_category}"
        expect(response).to have_http_status(:success)

        get "/buyer/public_markets/#{completed_market.identifier}/summary"
        expect(response).to have_http_status(:success)
      end

      it 'allows updates to wizard steps' do
        patch "/buyer/public_markets/#{completed_market.identifier}/setup"
        expect(response).to have_http_status(:redirect)
      end

      it 're-submits summary and enqueues new configuration summary PDF generation job' do
        patch "/buyer/public_markets/#{completed_market.identifier}/summary"

        expect(response).to redirect_to(buyer_sync_status_path(completed_market.identifier))
        expect(GeneratePublicMarketConfigurationSummaryPdfJob).to have_been_enqueued.with(
          completed_market.id, request_host: 'www.example.com', request_protocol: 'http://'
        )
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

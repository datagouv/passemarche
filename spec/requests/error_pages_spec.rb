# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Error pages', type: :request do
  def heading(error_page)
    I18n.t("errors.pages.#{error_page}.heading")
  end

  context 'when the market application does not exist' do
    it 'renders the market application not found page' do
      get application_mode_candidate_market_application_path('NONEXISTENT')

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:market_application_not_found))
    end

    it 'renders the page in the requested locale' do
      get application_mode_candidate_market_application_path('NONEXISTENT', locale: 'en')

      expect(CGI.unescapeHTML(response.body)).to include(I18n.t('errors.pages.market_application_not_found.heading', locale: :en))
    end

    it 'returns an empty not found response for non HTML formats' do
      get application_mode_candidate_market_application_path('NONEXISTENT', format: :json)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_empty
    end
  end

  context 'when the public market does not exist' do
    it 'renders the public market not found page' do
      get buyer_sync_status_path('NONEXISTENT')

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:public_market_not_found))
    end
  end

  context 'when the buyer wizard step does not exist' do
    let(:public_market) { create(:public_market) }

    it 'renders the generic not found page' do
      get step_buyer_public_market_path(public_market.identifier, 'unknown_step')

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:not_found))
    end
  end

  context 'when the candidate wizard step does not exist' do
    let(:market_application) { create(:market_application, public_market: create(:public_market, :completed)) }

    before do
      allow_any_instance_of(Candidate::ApplicationController).to receive(:current_candidate).and_return(create(:user))
    end

    it 'renders the generic not found page' do
      get step_candidate_market_application_path(market_application.identifier, 'unknown_step')

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:not_found))
    end
  end

  context 'when the missing record has no dedicated page' do
    before { sign_in create(:admin_user), scope: :admin_user }

    it 'renders the generic not found page' do
      get admin_editor_path(0)

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:not_found))
    end
  end

  context 'when the public market is already published' do
    let(:public_market) { create(:public_market, :published) }

    it 'renders the published market page' do
      patch buyer_lot_types_path(public_market.identifier), params: { lot_ids: [] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:public_market_published))
    end
  end

  context 'when the groupement feature is disabled' do
    before { allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false) }

    it 'renders the generic not found page' do
      get candidate_grouping_invitation_path('any-token')

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:not_found))
    end
  end
end

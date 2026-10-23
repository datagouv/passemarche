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

  context 'when the missing record has no dedicated page' do
    before { sign_in create(:admin_user), scope: :admin_user }

    it 'renders the generic not found page' do
      get admin_editor_path(0)

      expect(response).to have_http_status(:not_found)
      expect(CGI.unescapeHTML(response.body)).to include(heading(:not_found))
    end
  end
end

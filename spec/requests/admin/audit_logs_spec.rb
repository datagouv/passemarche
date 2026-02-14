# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::AuditLogs', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/historique' do
    it 'returns http success' do
      get '/admin/historique'
      expect(response).to have_http_status(:success)
    end

    it 'displays the page title' do
      get '/admin/historique'
      expect(response.body).to include('Historique des modifications')
    end

    it 'displays empty state when no versions exist' do
      get '/admin/historique'
      expect(response.body).to include('Aucune modification enregistrée')
    end

    context 'with audit entries' do
      let!(:market_attribute) do
        PaperTrail.request.whodunnit = admin_user.id
        create(:market_attribute, buyer_name: 'Test field')
      end

      it 'displays version entries' do
        get '/admin/historique'
        expect(response.body).to include('Création')
      end

      it 'displays the detail link' do
        get '/admin/historique'
        expect(response.body).to include('Voir le détail')
      end
    end

    context 'with text filter' do
      let!(:market_attribute) do
        PaperTrail.request.whodunnit = admin_user.id
        create(:market_attribute, category_key: 'identite_entreprise', buyer_name: 'SIRET')
      end

      it 'filters by query' do
        get '/admin/historique', params: { query: 'identite' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with date filter' do
      it 'filters by date range' do
        get '/admin/historique', params: { date_from: 1.day.ago.to_date.to_s, date_to: Date.current.to_s }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with user filter' do
      it 'filters by admin user' do
        get '/admin/historique', params: { admin_user_id: admin_user.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /admin/historique/:id' do
    let!(:market_attribute) do
      PaperTrail.request.whodunnit = admin_user.id
      create(:market_attribute, buyer_name: 'Test field')
    end

    let(:version) { PaperTrail::Version.last }

    it 'returns http success' do
      get "/admin/historique/#{version.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays the version details' do
      get "/admin/historique/#{version.id}"
      expect(response.body).to include('Détail de la modification')
      expect(response.body).to include('Création')
    end

    context 'with a modification version' do
      before do
        PaperTrail.request.whodunnit = admin_user.id
        market_attribute.update!(buyer_name: 'Updated field')
      end

      let(:modification_version) { PaperTrail::Version.last }

      it 'displays before and after values' do
        get "/admin/historique/#{modification_version.id}"
        expect(response.body).to include('Test field')
        expect(response.body).to include('Updated field')
      end
    end
  end

  context 'without authentication' do
    before do
      sign_out admin_user
    end

    it 'redirects to login for index' do
      get '/admin/historique'
      expect(response).to have_http_status(:redirect)
    end

    it 'redirects to login for show' do
      get '/admin/historique/1'
      expect(response).to have_http_status(:redirect)
    end
  end
end

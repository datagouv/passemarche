# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Dashboards', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:editor) { create(:editor, authorized: true, active: true) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/dashboard' do
    it 'returns http success' do
      get '/admin/dashboard'
      expect(response).to have_http_status(:success)
    end

    it 'displays the dashboard title' do
      get '/admin/dashboard'
      # HTML escapes the apostrophe, so check for key part of title
      expect(response.body).to include('Suivi d')
      expect(response.body).to include('activit')
    end

    context 'with editor filter' do
      it 'returns http success' do
        get "/admin/dashboard?editor_id=#{editor.id}"
        expect(response).to have_http_status(:success)
      end

      it 'displays editor name in title' do
        get "/admin/dashboard?editor_id=#{editor.id}"
        expect(response.body).to include(editor.name)
      end
    end

    context 'with invalid editor_id' do
      it 'returns http success and shows global stats' do
        get '/admin/dashboard?editor_id=invalid'
        expect(response).to have_http_status(:success)
        # HTML escapes the apostrophe, so check for key part of title
        expect(response.body).to include('Suivi d')
      end
    end
  end

  describe 'GET /admin/dashboard/export' do
    it 'returns http success with CSV content type' do
      get '/admin/dashboard/export'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/csv')
    end

    it 'returns CSV filename with global suffix' do
      get '/admin/dashboard/export'
      expect(response.headers['Content-Disposition']).to include('statistiques-passe-marche-global')
    end

    context 'with editor filter' do
      it 'returns CSV with editor name in filename' do
        get "/admin/dashboard/export?editor_id=#{editor.id}"
        expect(response.headers['Content-Disposition']).to include(editor.name.parameterize)
      end
    end
  end

  context 'without authentication' do
    before do
      sign_out admin_user
    end

    describe 'GET /admin/dashboard' do
      it 'redirects to login' do
        get '/admin/dashboard'
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'GET /admin/dashboard/export' do
      it 'redirects to login' do
        get '/admin/dashboard/export'
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe 'Admin::Editors', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:editor) { create(:editor) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/editors' do
    it 'returns http success' do
      get '/admin/editors'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/editors/:id' do
    it 'returns http success' do
      get "/admin/editors/#{editor.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays the client_id' do
      get "/admin/editors/#{editor.id}"
      expect(response.body).to include(editor.client_id)
    end

    it 'includes the client_secret in data attribute for toggle' do
      get "/admin/editors/#{editor.id}"
      expect(response.body).to include(editor.client_secret)
    end
  end

  describe 'GET /admin/editors/new' do
    it 'returns http success' do
      get '/admin/editors/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/editors' do
    it 'creates a new editor with auto-generated credentials' do
      editor_params = {
        editor: {
          name: 'Test Editor'
        }
      }

      expect do
        post '/admin/editors', params: editor_params
      end.to change(Editor, :count).by(1)

      expect(response).to have_http_status(:redirect)

      created_editor = Editor.last
      expect(created_editor.client_id).to be_present
      expect(created_editor.client_id.length).to eq(32)
      expect(created_editor.client_secret).to be_present
      expect(created_editor.client_secret.length).to eq(64)
    end

    it 'creates a Doorkeeper application for the new editor' do
      editor_params = {
        editor: {
          name: 'Test Editor'
        }
      }

      expect do
        post '/admin/editors', params: editor_params
      end.to change(CustomDoorkeeperApplication, :count).by(1)

      created_editor = Editor.last
      doorkeeper_app = CustomDoorkeeperApplication.find_by(uid: created_editor.client_id)
      expect(doorkeeper_app).to be_present
      expect(doorkeeper_app.secret).to eq(created_editor.client_secret)
    end
  end

  describe 'GET /admin/editors/:id/edit' do
    it 'returns http success' do
      get "/admin/editors/#{editor.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT /admin/editors/:id' do
    it 'updates the editor' do
      editor_params = {
        editor: {
          name: 'Updated Editor Name'
        }
      }

      put "/admin/editors/#{editor.id}", params: editor_params
      expect(response).to have_http_status(:redirect)

      editor.reload
      expect(editor.name).to eq('Updated Editor Name')
    end
  end

  describe 'DELETE /admin/editors/:id' do
    it 'destroys the editor' do
      editor_to_delete = create(:editor)

      expect do
        delete "/admin/editors/#{editor_to_delete.id}"
      end.to change(Editor, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end
  end
end

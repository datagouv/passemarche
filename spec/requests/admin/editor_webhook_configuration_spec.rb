# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Editors webhook configuration', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:editor) { create(:editor) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/editors/:id/edit' do
    it 'shows webhook configuration fields' do
      get edit_admin_editor_path(editor)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Configuration Webhook')
      expect(response.body).to include('URL de webhook de complétion')
      expect(response.body).to include('URL de redirection')
      expect(response.body).to include('Secret webhook')
    end

    context 'with webhook secret present' do
      before { editor.update!(webhook_secret: 'existing_secret') }

      it 'shows masked secret and regenerate button' do
        get edit_admin_editor_path(editor)

        expect(response.body).to include('••••••••••••••••')
        expect(response.body).to include('Générer un nouveau secret')
      end
    end

    context 'without webhook secret' do
      before { editor.update!(webhook_secret: nil) }

      it 'shows generate button' do
        get edit_admin_editor_path(editor)

        expect(response.body).to include('Générer un secret')
      end
    end
  end

  describe 'PATCH /admin/editors/:id' do
    context 'with valid webhook configuration' do
      let(:valid_params) do
        {
          editor: {
            name: editor.name,
            client_id: editor.client_id,
            client_secret: editor.client_secret,
            completion_webhook_url: 'https://example.com/webhook',
            redirect_url: 'https://example.com/success'
          }
        }
      end

      it 'updates webhook configuration' do
        patch admin_editor_path(editor), params: valid_params

        editor.reload
        expect(editor.completion_webhook_url).to eq('https://example.com/webhook')
        expect(editor.redirect_url).to eq('https://example.com/success')
        expect(response).to redirect_to(admin_editor_path(editor))
      end
    end

    context 'with invalid webhook configuration' do
      let(:invalid_params) do
        {
          editor: {
            name: editor.name,
            client_id: editor.client_id,
            client_secret: editor.client_secret,
            completion_webhook_url: 'not a url'
          }
        }
      end

      it 'shows errors' do
        patch admin_editor_path(editor), params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Erreurs')
      end
    end
  end

  describe 'POST /admin/editors/:id/generate_webhook_secret' do
    it 'generates a new webhook secret' do
      expect {
        post generate_webhook_secret_admin_editor_path(editor)
      }.to change { editor.reload.webhook_secret }

      expect(response).to redirect_to(edit_admin_editor_path(editor))
      expect(flash[:notice]).to eq('Nouveau secret webhook généré avec succès')
    end

    it 'generates a valid secret' do
      post generate_webhook_secret_admin_editor_path(editor)

      editor.reload
      expect(editor.webhook_secret).to be_present
      expect(editor.webhook_secret.length).to eq(64)
    end

    context 'when save fails' do
      before do
        allow_any_instance_of(Editor).to receive(:save).and_return(false)
      end

      it 'shows error message' do
        post generate_webhook_secret_admin_editor_path(editor)

        expect(response).to redirect_to(edit_admin_editor_path(editor))
        expect(flash[:alert]).to eq('Erreur lors de la génération du secret')
      end
    end
  end

  describe 'GET /admin/editors/:id' do
    context 'with webhook configured' do
      before do
        editor.update!(
          completion_webhook_url: 'https://example.com/webhook',
          redirect_url: 'https://example.com/success',
          webhook_secret: 'secret123'
        )
      end

      it 'displays webhook configuration' do
        get admin_editor_path(editor)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Configuration Webhook')
        expect(response.body).to include('https://example.com/webhook')
        expect(response.body).to include('https://example.com/success')
        expect(response.body).to include('Oui') # Secret configured
      end
    end

    context 'without webhook configured' do
      before do
        editor.update!(completion_webhook_url: nil, webhook_secret: nil)
      end

      it 'shows webhook not configured' do
        get admin_editor_path(editor)

        expect(response.body).to include('Webhook non configuré')
      end
    end
  end
end

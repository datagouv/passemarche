# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Authorization', type: :request do
  let(:admin_user) { create(:admin_user, :admin) }
  let(:lecteur_user) { create(:admin_user, :lecteur) }

  describe '#require_admin_role!' do
    context 'when user is admin' do
      before { sign_in admin_user }

      it 'allows access to write actions' do
        get new_admin_editor_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is lecteur' do
      before { sign_in lecteur_user }

      it 'redirects from write actions with flash alert' do
        get new_admin_editor_path
        expect(response).to redirect_to(admin_root_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('admin.authorization.insufficient_permissions'))
      end

      it 'allows access to read actions' do
        get admin_editors_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#current_user_can_modify?' do
    context 'when user is admin' do
      before { sign_in admin_user }

      it 'shows modification buttons in views' do
        get admin_editors_path
        expect(response.body).to include(I18n.t('admin.editors.index.add'))
      end
    end

    context 'when user is lecteur' do
      before { sign_in lecteur_user }

      it 'hides modification buttons in views' do
        get admin_editors_path
        expect(response.body).not_to include(new_admin_editor_path)
      end
    end
  end
end

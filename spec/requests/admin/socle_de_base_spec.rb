# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::SocleDeBase', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/socle_de_base' do
    let!(:works_type) { create(:market_type, :works) }
    let!(:supplies_type) { create(:market_type) }
    let!(:services_type) { create(:market_type, :services) }

    let!(:identity_attribute) do
      attr = create(:market_attribute,
        key: 'test_identity',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification',
        api_name: 'Insee',
        api_key: 'siret')
      attr.market_types << [works_type, supplies_type, services_type]
      attr
    end

    let!(:exclusion_attribute) do
      attr = create(:market_attribute,
        key: 'test_exclusion',
        category_key: 'motifs_exclusion',
        subcategory_key: 'motifs_exclusion_fiscales_et_sociales')
      attr.market_types << [works_type]
      attr
    end

    it 'returns http success' do
      get '/admin/socle_de_base'
      expect(response).to have_http_status(:success)
    end

    it 'displays the page title' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Socle de base')
    end

    it 'renders a table with correct headers' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Catégorie')
      expect(response.body).to include('Sous Catégorie')
      expect(response.body).to include('Champ')
      expect(response.body).to include('Type de marché')
      expect(response.body).to include('Source')
      expect(response.body).to include('Actions')
    end

    it 'displays market attributes as table rows' do
      get '/admin/socle_de_base'
      expect(response.body).to include("data-item-id=\"#{identity_attribute.id}\"")
      expect(response.body).to include("data-item-id=\"#{exclusion_attribute.id}\"")
    end

    it 'displays market type badges with active styling' do
      get '/admin/socle_de_base'
      expect(response.body).to include('fr-badge--blue-cumulus')
    end

    it 'displays source badges' do
      get '/admin/socle_de_base'
      expect(response.body).to include('API Insee')
      expect(response.body).to include('Manuel')
    end

    it 'does not display soft-deleted attributes' do
      deleted_attribute = create(:market_attribute,
        key: 'test_deleted',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification',
        deleted_at: Time.current)

      get '/admin/socle_de_base'
      expect(response.body).not_to include("data-item-id=\"#{deleted_attribute.id}\"")
    end

    it 'displays edit buttons' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Modifier')
    end

    it 'filters by category' do
      get '/admin/socle_de_base', params: { category: 'identite_entreprise' }

      expect(response.body).to include("data-item-id=\"#{identity_attribute.id}\"")
      expect(response.body).not_to include("data-item-id=\"#{exclusion_attribute.id}\"")
    end

    it 'filters by source' do
      get '/admin/socle_de_base', params: { source: 'api' }

      expect(response.body).to include("data-item-id=\"#{identity_attribute.id}\"")
      expect(response.body).not_to include("data-item-id=\"#{exclusion_attribute.id}\"")
    end

    it 'returns all with no filters' do
      get '/admin/socle_de_base'

      expect(response.body).to include("data-item-id=\"#{identity_attribute.id}\"")
      expect(response.body).to include("data-item-id=\"#{exclusion_attribute.id}\"")
    end
  end

  describe 'PATCH /admin/socle_de_base/reorder' do
    let!(:attr_a) { create(:market_attribute, key: 'attr_a', position: 0) }
    let!(:attr_b) { create(:market_attribute, key: 'attr_b', position: 1) }
    let!(:attr_c) { create(:market_attribute, key: 'attr_c', position: 2) }

    it 'updates positions according to the new order' do
      patch '/admin/socle_de_base/reorder',
        params: { ordered_ids: [attr_c.id, attr_a.id, attr_b.id] },
        as: :json

      expect(response).to have_http_status(:ok)
      expect(attr_c.reload.position).to eq(0)
      expect(attr_a.reload.position).to eq(1)
      expect(attr_b.reload.position).to eq(2)
    end

    it 'assigns sequential positions starting from zero' do
      patch '/admin/socle_de_base/reorder',
        params: { ordered_ids: [attr_b.id, attr_c.id, attr_a.id] },
        as: :json

      expect(attr_b.reload.position).to eq(0)
      expect(attr_c.reload.position).to eq(1)
      expect(attr_a.reload.position).to eq(2)
    end

    it 'returns bad request when ordered_ids is missing' do
      patch '/admin/socle_de_base/reorder', params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'POST /admin/socle_de_base' do
    let(:csv_content) { file_fixture('field_configuration_import.csv') }

    context 'with a valid CSV file' do
      it 'imports and redirects with success flash' do
        post '/admin/socle_de_base', params: {
          socle_de_base: { csv_file: fixture_file_upload('field_configuration_import.csv', 'text/csv') }
        }
        expect(response).to redirect_to(admin_socle_de_base_index_path)
        follow_redirect!
        expect(response.body).to include('Import réussi')
      end
    end

    context 'without a file' do
      it 'redirects with error flash' do
        post '/admin/socle_de_base', params: { socle_de_base: {} }
        expect(response).to redirect_to(admin_socle_de_base_index_path)
        follow_redirect!
        expect(response.body).to include('Veuillez sélectionner un fichier CSV')
      end
    end
  end

  describe 'PATCH /admin/socle_de_base/:id/archive' do
    let!(:attribute) { create(:market_attribute, key: 'test_field') }

    it 'archives the attribute and redirects with notice' do
      patch "/admin/socle_de_base/#{attribute.id}/archive"
      expect(response).to redirect_to(admin_socle_de_base_index_path)
      expect(flash[:notice]).to include('test_field')
      expect(attribute.reload.deleted_at).to be_present
    end

    it 'shows alert when attribute is already archived' do
      attribute.update!(deleted_at: 1.day.ago)
      patch "/admin/socle_de_base/#{attribute.id}/archive"
      expect(response).to redirect_to(admin_socle_de_base_index_path)
      expect(flash[:alert]).to be_present
    end

    it 'displays archive button on index page' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Archiver')
    end
  end

  context 'with lecteur role' do
    let(:admin_user) { create(:admin_user, :lecteur) }

    describe 'PATCH /admin/socle_de_base/reorder' do
      it 'redirects to admin root' do
        patch '/admin/socle_de_base/reorder',
          params: { ordered_ids: [1, 2] },
          as: :json

        expect(response).to redirect_to(admin_root_path)
      end
    end
  end

  context 'without authentication' do
    before do
      sign_out admin_user
    end

    describe 'GET /admin/socle_de_base' do
      it 'redirects to login' do
        get '/admin/socle_de_base'
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'PATCH /admin/socle_de_base/reorder' do
      it 'redirects to login' do
        patch '/admin/socle_de_base/reorder', params: { ordered_ids: [1, 2] }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'PATCH /admin/socle_de_base/:id/archive' do
      it 'redirects to login' do
        attribute = create(:market_attribute)
        patch "/admin/socle_de_base/#{attribute.id}/archive"
        expect(response).to have_http_status(:redirect)
        expect(attribute.reload.deleted_at).to be_nil
      end
    end
  end
end

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

    it 'includes a link to create a new field' do
      get '/admin/socle_de_base'
      expect(response.body).to include(new_admin_socle_de_base_path)
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

  describe 'GET /admin/socle_de_base/new' do
    let!(:category) { create(:category, :with_labels, key: 'identite_entreprise') }
    let!(:subcategory) { create(:subcategory, :with_labels, key: 'identification', category:) }
    let!(:works_type) { create(:market_type, :works) }

    it 'returns http success' do
      get '/admin/socle_de_base/new'
      expect(response).to have_http_status(:success)
    end

    it 'displays the form title' do
      get '/admin/socle_de_base/new'
      expect(response.body).to include('Créer un nouveau champ')
    end

    it 'displays the form sections' do
      get '/admin/socle_de_base/new'
      expect(response.body).to include(I18n.t('admin.socle_de_base.show.general_info'))
      expect(response.body).to include(I18n.t('admin.socle_de_base.show.description'))
      expect(response.body).to include(I18n.t('admin.socle_de_base.show.configuration'))
    end

    it 'displays categories in select' do
      get '/admin/socle_de_base/new'
      expect(response.body).to include(category.buyer_label)
    end

    it 'displays market types as checkboxes' do
      get '/admin/socle_de_base/new'
      expect(response.body).to include('Travaux')
    end
  end

  describe 'POST /admin/socle_de_base' do
    let!(:category) { create(:category, key: 'identite_entreprise') }
    let!(:subcategory) { create(:subcategory, key: 'identification', category:) }
    let!(:works_type) { create(:market_type, :works) }

    let(:valid_params) do
      {
        market_attribute: {
          input_type: 'text_input',
          mandatory: '1',
          configuration_mode: 'manual',
          subcategory_id: subcategory.id.to_s,
          buyer_name: 'Numéro SIRET',
          candidate_name: 'Votre SIRET',
          buyer_description: 'Identifiant SIRET',
          candidate_description: 'Renseignez votre SIRET',
          market_type_ids: [works_type.id.to_s]
        }
      }
    end

    context 'with valid params' do
      it 'creates a market attribute' do
        expect { post '/admin/socle_de_base', params: valid_params }.to change(MarketAttribute, :count).by(1)
      end

      it 'redirects to index with success notice' do
        post '/admin/socle_de_base', params: valid_params
        expect(response).to redirect_to(admin_socle_de_base_index_path)
        follow_redirect!
        expect(response.body).to include('créé avec succès')
      end
    end

    context 'with invalid params' do
      it 're-renders the form with errors when buyer_name is missing' do
        post '/admin/socle_de_base', params: {
          market_attribute: valid_params[:market_attribute].merge(buyer_name: '')
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 're-renders the form with errors when market_type_ids is empty' do
        post '/admin/socle_de_base', params: {
          market_attribute: valid_params[:market_attribute].merge(market_type_ids: [''])
        }
        expect(response).to have_http_status(:unprocessable_content)
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

  describe 'GET /admin/socle_de_base/:id' do
    let!(:market_attribute) do
      create(:market_attribute,
        key: 'test_show',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification',
        api_name: 'Insee',
        api_key: 'siret')
    end

    it 'returns http success' do
      get "/admin/socle_de_base/#{market_attribute.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays the configuration section' do
      get "/admin/socle_de_base/#{market_attribute.id}"
      expect(response.body).to include('Configuration')
    end
  end

  describe 'GET /admin/socle_de_base/:id/edit' do
    let!(:market_attribute) do
      create(:market_attribute,
        key: 'test_edit',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification')
    end

    it 'returns http success' do
      get "/admin/socle_de_base/#{market_attribute.id}/edit"
      expect(response).to have_http_status(:success)
    end

    it 'displays the form' do
      get "/admin/socle_de_base/#{market_attribute.id}/edit"
      expect(response.body).to include('Modifier le champ')
    end
  end

  describe 'PATCH /admin/socle_de_base/:id' do
    let(:market_type) { create(:market_type, code: 'works') }
    let!(:market_attribute) do
      create(:market_attribute,
        key: 'test_update',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification').tap { |a| a.market_types << market_type }
    end

    let(:valid_update_params) do
      {
        buyer_name: 'Buyer field',
        candidate_name: 'Candidate field',
        market_type_ids: [market_type.id.to_s]
      }
    end

    it 'updates and redirects on success' do
      patch "/admin/socle_de_base/#{market_attribute.id}", params: {
        market_attribute: valid_update_params.merge(input_type: 'text_input', mandatory: true)
      }
      expect(response).to redirect_to(admin_socle_de_base_path(market_attribute))
    end

    it 'updates the attribute values' do
      patch "/admin/socle_de_base/#{market_attribute.id}", params: {
        market_attribute: valid_update_params.merge(input_type: 'text_input', mandatory: true)
      }
      market_attribute.reload
      expect(market_attribute.input_type).to eq('text_input')
      expect(market_attribute).to be_mandatory
    end

    it 'updates buyer and candidate fields' do
      patch "/admin/socle_de_base/#{market_attribute.id}", params: {
        market_attribute: valid_update_params.merge(
          buyer_name: 'Titre acheteur',
          buyer_description: 'Desc acheteur',
          candidate_name: 'Titre candidat',
          candidate_description: 'Desc candidat'
        )
      }
      market_attribute.reload
      expect(market_attribute.buyer_name).to eq('Titre acheteur')
      expect(market_attribute.candidate_name).to eq('Titre candidat')
    end
  end

  describe 'PATCH /admin/socle_de_base/:id/archive' do
    let!(:market_attribute) do
      create(:market_attribute,
        key: 'test_archive',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification')
    end

    it 'soft-deletes and redirects to index' do
      patch "/admin/socle_de_base/#{market_attribute.id}/archive"
      expect(response).to redirect_to(admin_socle_de_base_index_path)
      expect(market_attribute.reload.deleted_at).not_to be_nil
    end
  end

  describe 'GET /admin/socle_de_base/export' do
    let!(:works_type) { create(:market_type, :works) }
    let!(:services_type) { create(:market_type, :services) }

    let!(:identity_attribute) do
      create(:market_attribute,
        key: 'test_identity',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification',
        api_name: 'Insee',
        api_key: 'siret',
        market_types: [works_type, services_type])
    end

    let!(:exclusion_attribute) do
      create(:market_attribute,
        key: 'test_exclusion',
        category_key: 'motifs_exclusion',
        subcategory_key: 'motifs_exclusion_fiscales_et_sociales',
        market_types: [works_type])
    end

    it 'returns a CSV file' do
      get '/admin/socle_de_base/export'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/csv')
    end

    it 'includes correct headers in CSV' do
      get '/admin/socle_de_base/export'
      csv = CSV.parse(response.body, col_sep: ';', headers: true)
      expect(csv.headers).to include('Clé', 'Catégorie (clé)', 'Catégorie acheteur', 'Obligatoire',
        'Source (api_name)', 'Types de marché')
    end

    it 'includes all active attributes without filters' do
      get '/admin/socle_de_base/export'
      csv = CSV.parse(response.body, col_sep: ';', headers: true)
      keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
      expect(keys).to include('test_identity', 'test_exclusion')
    end

    it 'filters by category' do
      get '/admin/socle_de_base/export', params: { category: 'identite_entreprise' }
      csv = CSV.parse(response.body, col_sep: ';', headers: true)
      keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
      expect(keys).to include('test_identity')
      expect(keys).not_to include('test_exclusion')
    end

    it 'filters by source' do
      get '/admin/socle_de_base/export', params: { source: 'api' }
      csv = CSV.parse(response.body, col_sep: ';', headers: true)
      keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
      expect(keys).to include('test_identity')
      expect(keys).not_to include('test_exclusion')
    end

    it 'sets Content-Disposition with correct filename' do
      get '/admin/socle_de_base/export'
      expect(response.headers['Content-Disposition']).to include("socle-de-base-#{Date.current}.csv")
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

    describe 'GET /admin/socle_de_base/new' do
      it 'redirects to login' do
        get '/admin/socle_de_base/new'
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'POST /admin/socle_de_base' do
      it 'redirects to login' do
        post '/admin/socle_de_base', params: { market_attribute: { buyer_name: 'test' } }
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

    describe 'GET /admin/socle_de_base/export' do
      it 'redirects to login' do
        get '/admin/socle_de_base/export'
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end

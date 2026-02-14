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
      expect(response.body).to include("data-attribute-id=\"#{identity_attribute.id}\"")
      expect(response.body).to include("data-attribute-id=\"#{exclusion_attribute.id}\"")
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
      expect(response.body).not_to include("data-attribute-id=\"#{deleted_attribute.id}\"")
    end

    it 'displays edit buttons' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Modifier')
    end

    it 'includes a link to create a new field' do
      get '/admin/socle_de_base'
      expect(response.body).to include(new_admin_socle_de_base_path)
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

    it 'displays the four form blocks' do
      get '/admin/socle_de_base/new'
      expect(response.body).to include('Informations générales')
      expect(response.body).to include('Configuration de la source')
      expect(response.body).to include('Descriptions acheteur / candidat')
      expect(response.body).to include('Types de marché')
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
          source: 'manual',
          category_key: category.key,
          subcategory_key: subcategory.key,
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
  end
end

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
  end
end

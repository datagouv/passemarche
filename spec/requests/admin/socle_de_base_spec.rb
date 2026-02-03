# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::SocleDeBase', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/socle_de_base' do
    let!(:identity_attribute) do
      create(:market_attribute,
        key: 'test_identity',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification')
    end
    let!(:exclusion_attribute) do
      create(:market_attribute,
        key: 'test_exclusion',
        category_key: 'motifs_exclusion',
        subcategory_key: 'motifs_exclusion_fiscales_et_sociales')
    end

    it 'returns http success' do
      get '/admin/socle_de_base'
      expect(response).to have_http_status(:success)
    end

    it 'displays the page title' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Socle de base')
    end

    it 'displays attributes from the default tab (identite_entreprise)' do
      get '/admin/socle_de_base'
      expect(response.body).to include('test_identity')
      expect(response.body).not_to include('test_exclusion')
    end

    context 'with tab parameter' do
      it 'filters by the specified category tab' do
        get '/admin/socle_de_base?tab=motifs_exclusion'
        expect(response.body).to include('test_exclusion')
        expect(response.body).not_to include('test_identity')
      end

      it 'falls back to default tab with invalid tab parameter' do
        get '/admin/socle_de_base?tab=invalid_tab'
        expect(response.body).to include('test_identity')
      end
    end

    context 'with search parameter' do
      it 'filters by key containing the search term' do
        get '/admin/socle_de_base?q=identity'
        expect(response.body).to include('test_identity')
      end

      it 'returns empty when no match' do
        get '/admin/socle_de_base?q=nonexistent'
        expect(response.body).not_to include('test_identity')
      end
    end

    context 'with market_type_id parameter' do
      let(:market_type) { create(:market_type) }
      let!(:attribute_with_type) do
        create(:market_attribute,
          key: 'test_with_type',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_entreprise_identification',
          market_types: [market_type])
      end

      it 'filters by market type' do
        get "/admin/socle_de_base?market_type_id=#{market_type.id}"
        expect(response.body).to include('test_with_type')
        expect(response.body).not_to include('test_identity')
      end
    end

    context 'with source parameter' do
      let!(:api_attribute) do
        create(:market_attribute,
          key: 'test_api_source',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_entreprise_identification',
          api_name: 'Insee',
          api_key: 'siret')
      end

      it 'filters by api source' do
        get '/admin/socle_de_base?source=api'
        expect(response.body).to include('test_api_source')
        expect(response.body).not_to include('test_identity')
      end

      it 'filters by manual source' do
        get '/admin/socle_de_base?source=manual'
        expect(response.body).to include('test_identity')
        expect(response.body).not_to include('test_api_source')
      end
    end

    context 'with mandatory parameter' do
      let!(:mandatory_attribute) do
        create(:market_attribute,
          key: 'test_mandatory',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_entreprise_identification',
          mandatory: true)
      end
      let!(:optional_attribute) do
        create(:market_attribute,
          key: 'test_optional',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_entreprise_identification',
          mandatory: false)
      end

      it 'filters mandatory attributes' do
        get '/admin/socle_de_base?mandatory=true'
        expect(response.body).to include('test_mandatory')
        expect(response.body).not_to include('test_optional')
      end

      it 'filters optional attributes' do
        get '/admin/socle_de_base?mandatory=false'
        expect(response.body).to include('test_optional')
        expect(response.body).not_to include('test_mandatory')
      end
    end

    context 'with combined filters' do
      let(:market_type) { create(:market_type) }
      let!(:combined_attribute) do
        create(:market_attribute,
          key: 'test_combined',
          category_key: 'identite_entreprise',
          subcategory_key: 'identite_entreprise_identification',
          mandatory: true,
          api_name: 'Insee',
          api_key: 'siret',
          market_types: [market_type])
      end

      it 'applies all filters together' do
        get "/admin/socle_de_base?tab=identite_entreprise&q=combined&market_type_id=#{market_type.id}&source=api&mandatory=true"
        expect(response.body).to include('test_combined')
        expect(response.body).not_to include('test_identity')
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
  end
end

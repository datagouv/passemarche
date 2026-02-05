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

    it 'displays all categories as accordion panels' do
      get '/admin/socle_de_base'
      expect(response.body).to include('accordion-cat-identite_entreprise')
      expect(response.body).to include('accordion-cat-motifs_exclusion')
    end

    it 'displays subcategories within categories' do
      get '/admin/socle_de_base'
      expect(response.body).to include('accordion-sub-identite_entreprise_identification')
      expect(response.body).to include('accordion-sub-motifs_exclusion_fiscales_et_sociales')
    end

    it 'displays field-level accordions' do
      get '/admin/socle_de_base'
      expect(response.body).to include("accordion-field-#{identity_attribute.id}")
      expect(response.body).to include("accordion-field-#{exclusion_attribute.id}")
    end

    it 'does not display soft-deleted attributes' do
      deleted_attribute = create(:market_attribute,
        key: 'test_deleted',
        category_key: 'identite_entreprise',
        subcategory_key: 'identite_entreprise_identification',
        deleted_at: Time.current)

      get '/admin/socle_de_base'
      expect(response.body).not_to include("accordion-field-#{deleted_attribute.id}")
    end

    it 'displays buyer and candidate labels at each level' do
      get '/admin/socle_de_base'
      expect(response.body).to include('Acheteur')
      expect(response.body).to include('Candidat')
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

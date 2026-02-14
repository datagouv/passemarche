# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Categories', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/categories' do
    let!(:category) { create(:category, :with_labels, position: 0) }
    let!(:subcategory) { create(:subcategory, :with_labels, category:, position: 0) }

    it 'returns http success' do
      get '/admin/categories'
      expect(response).to have_http_status(:success)
    end

    it 'does not display soft-deleted categories' do
      deleted = create(:category, :with_labels, :inactive)
      get '/admin/categories'
      expect(response.body).not_to include(deleted.buyer_label)
    end

    it 'does not display soft-deleted subcategories' do
      deleted = create(:subcategory, :with_labels, :inactive, category:)
      get '/admin/categories'
      expect(response.body).not_to include(deleted.buyer_label)
    end
  end

  describe 'PATCH /admin/categories/reorder' do
    let!(:cat_a) { create(:category, key: 'cat_a', position: 0) }
    let!(:cat_b) { create(:category, key: 'cat_b', position: 1) }
    let!(:cat_c) { create(:category, key: 'cat_c', position: 2) }

    it 'updates positions according to the new order' do
      patch '/admin/categories/reorder',
        params: { ordered_ids: [cat_c.id, cat_a.id, cat_b.id] },
        as: :json

      expect(response).to have_http_status(:ok)
      expect(cat_c.reload.position).to eq(0)
      expect(cat_a.reload.position).to eq(1)
      expect(cat_b.reload.position).to eq(2)
    end

    it 'returns bad request when ordered_ids is missing' do
      patch '/admin/categories/reorder', params: {}, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'PATCH /admin/subcategories/reorder' do
    let(:category) { create(:category) }
    let!(:sub_a) { create(:subcategory, key: 'sub_a', category:, position: 0) }
    let!(:sub_b) { create(:subcategory, key: 'sub_b', category:, position: 1) }

    it 'updates subcategory positions' do
      patch '/admin/subcategories/reorder',
        params: { ordered_ids: [sub_b.id, sub_a.id] },
        as: :json

      expect(response).to have_http_status(:ok)
      expect(sub_b.reload.position).to eq(0)
      expect(sub_a.reload.position).to eq(1)
    end
  end

  describe 'GET /admin/categories/:id/edit' do
    let!(:category) { create(:category, :with_labels, position: 0) }

    it 'returns http success' do
      get "/admin/categories/#{category.id}/edit"
      expect(response).to have_http_status(:success)
    end

    it 'displays the edit modal title' do
      get "/admin/categories/#{category.id}/edit"
      expect(response.body).to include('Modifier une catégorie')
    end
  end

  describe 'PATCH /admin/categories/:id' do
    let!(:category) do
      create(:category, :with_labels, position: 0,
        buyer_label: 'Original Buyer',
        candidate_label: 'Original Candidate')
    end

    it 'updates and redirects on success' do
      patch "/admin/categories/#{category.id}", params: {
        category: { buyer_label: 'New Buyer', candidate_label: 'New Candidate' }
      }
      expect(response).to redirect_to(admin_categories_path)
    end

    it 'updates the category labels' do
      patch "/admin/categories/#{category.id}", params: {
        category: { buyer_label: 'New Buyer', candidate_label: 'New Candidate' }
      }
      category.reload
      expect(category.buyer_label).to eq('New Buyer')
      expect(category.candidate_label).to eq('New Candidate')
    end

    it 're-renders on blank label' do
      patch "/admin/categories/#{category.id}", params: {
        category: { buyer_label: '', candidate_label: 'Candidate' }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context 'without authentication' do
    before do
      sign_out admin_user
    end

    describe 'GET /admin/categories' do
      it 'redirects to login' do
        get '/admin/categories'
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'PATCH /admin/categories/reorder' do
      it 'returns unauthorized' do
        patch '/admin/categories/reorder', params: { ordered_ids: [1] }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

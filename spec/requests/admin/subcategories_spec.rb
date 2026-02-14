# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Subcategories', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:category) { create(:category, buyer_label: 'Cat Buyer', candidate_label: 'Cat Candidate') }
  let(:other_category) { create(:category, buyer_label: 'Other Buyer', candidate_label: 'Other Candidate') }
  let!(:subcategory) do
    create(:subcategory,
      category:,
      buyer_category: category,
      candidate_category: category,
      buyer_label: 'Sub Buyer',
      candidate_label: 'Sub Candidate')
  end

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'GET /admin/subcategories/:id/edit' do
    it 'returns http success' do
      get edit_admin_subcategory_path(subcategory)
      expect(response).to have_http_status(:success)
    end

    it 'displays the subcategory labels' do
      get edit_admin_subcategory_path(subcategory)
      expect(response.body).to include('Sub Buyer')
      expect(response.body).to include('Sub Candidate')
    end
  end

  describe 'PATCH /admin/subcategories/:id' do
    context 'with valid params' do
      it 'updates and redirects to categories page' do
        patch admin_subcategory_path(subcategory), params: {
          subcategory: {
            buyer_label: 'New Buyer',
            buyer_category_id: other_category.id,
            candidate_label: 'New Candidate',
            candidate_category_id: category.id
          }
        }

        expect(response).to redirect_to(admin_categories_path)
        subcategory.reload
        expect(subcategory.buyer_label).to eq('New Buyer')
        expect(subcategory.buyer_category).to eq(other_category)
        expect(subcategory.candidate_label).to eq('New Candidate')
        expect(subcategory.candidate_category).to eq(category)
      end
    end

    context 'with blank buyer_label' do
      it 're-renders the edit form with errors' do
        patch admin_subcategory_path(subcategory), params: {
          subcategory: {
            buyer_label: '',
            buyer_category_id: category.id,
            candidate_label: 'Candidate',
            candidate_category_id: category.id
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with blank candidate_label' do
      it 're-renders the edit form with errors' do
        patch admin_subcategory_path(subcategory), params: {
          subcategory: {
            buyer_label: 'Buyer',
            buyer_category_id: category.id,
            candidate_label: '',
            candidate_category_id: category.id
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  context 'without authentication' do
    before { sign_out admin_user }

    it 'redirects edit to login' do
      get edit_admin_subcategory_path(subcategory)
      expect(response).to have_http_status(:redirect)
    end

    it 'redirects update to login' do
      patch admin_subcategory_path(subcategory), params: {
        subcategory: { buyer_label: 'X', buyer_category_id: category.id,
                       candidate_label: 'Y', candidate_category_id: category.id }
      }
      expect(response).to have_http_status(:redirect)
    end
  end
end

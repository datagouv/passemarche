# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubcategoryUpdateService do
  let(:category_a) { create(:category, key: 'cat_a', buyer_label: 'Cat A Buyer', candidate_label: 'Cat A Candidate') }
  let(:category_b) { create(:category, key: 'cat_b', buyer_label: 'Cat B Buyer', candidate_label: 'Cat B Candidate') }
  let(:subcategory) do
    create(:subcategory,
      category: category_a,
      buyer_category: category_a,
      candidate_category: category_a,
      buyer_label: 'Original Buyer',
      candidate_label: 'Original Candidate')
  end

  describe '#perform' do
    context 'with valid params' do
      it 'updates buyer and candidate labels' do
        service = described_class.new(
          subcategory:,
          buyer_params: { label: 'New Buyer Label', category_id: category_a.id },
          candidate_params: { label: 'New Candidate Label', category_id: category_a.id }
        )

        service.perform

        expect(service).to be_success
        expect(subcategory.reload.buyer_label).to eq('New Buyer Label')
        expect(subcategory.reload.candidate_label).to eq('New Candidate Label')
      end

      it 'updates buyer category independently from candidate' do
        service = described_class.new(
          subcategory:,
          buyer_params: { label: 'Buyer', category_id: category_b.id },
          candidate_params: { label: 'Candidate', category_id: category_a.id }
        )

        service.perform

        expect(service).to be_success
        expect(subcategory.reload.buyer_category).to eq(category_b)
        expect(subcategory.reload.candidate_category).to eq(category_a)
      end

      it 'returns the subcategory as result' do
        service = described_class.new(
          subcategory:,
          buyer_params: { label: 'Buyer', category_id: category_a.id },
          candidate_params: { label: 'Candidate', category_id: category_a.id }
        )

        service.perform

        expect(service.result).to eq(subcategory)
      end
    end

    context 'with blank buyer_label' do
      it 'returns errors and does not save' do
        service = described_class.new(
          subcategory:,
          buyer_params: { label: '', category_id: category_a.id },
          candidate_params: { label: 'Candidate', category_id: category_a.id }
        )

        service.perform

        expect(service).to be_failure
        expect(service.errors[:buyer_label]).to be_present
        expect(subcategory.reload.buyer_label).to eq('Original Buyer')
      end
    end

    context 'with blank candidate_label' do
      it 'returns errors and does not save' do
        service = described_class.new(
          subcategory:,
          buyer_params: { label: 'Buyer', category_id: category_a.id },
          candidate_params: { label: '', category_id: category_a.id }
        )

        service.perform

        expect(service).to be_failure
        expect(service.errors[:candidate_label]).to be_present
        expect(subcategory.reload.candidate_label).to eq('Original Candidate')
      end
    end
  end
end

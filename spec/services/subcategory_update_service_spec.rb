# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubcategoryUpdateService do
  let(:category) { create(:category) }
  let(:other_category) { create(:category) }
  let(:subcategory) do
    create(:subcategory,
      category:,
      buyer_label: 'Original Buyer',
      candidate_label: 'Original Candidate')
  end

  describe '#perform' do
    context 'with valid params' do
      it 'updates buyer and candidate labels' do
        service = described_class.new(
          subcategory:,
          params: { buyer_label: 'New Buyer', candidate_label: 'New Candidate' }
        )

        service.perform

        expect(service).to be_success
        expect(subcategory.reload.buyer_label).to eq('New Buyer')
        expect(subcategory.reload.candidate_label).to eq('New Candidate')
      end

      it 'updates parent category' do
        service = described_class.new(
          subcategory:,
          params: { buyer_label: 'B', candidate_label: 'C', category_id: other_category.id }
        )

        service.perform

        expect(service).to be_success
        expect(subcategory.reload.category).to eq(other_category)
      end

      it 'returns the subcategory as result' do
        service = described_class.new(
          subcategory:,
          params: { buyer_label: 'B', candidate_label: 'C' }
        )

        service.perform

        expect(service.result).to eq(subcategory)
      end
    end

    context 'with blank buyer_label' do
      it 'returns errors and does not save' do
        service = described_class.new(
          subcategory:,
          params: { buyer_label: '', candidate_label: 'Candidate' }
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
          params: { buyer_label: 'Buyer', candidate_label: '' }
        )

        service.perform

        expect(service).to be_failure
        expect(service.errors[:candidate_label]).to be_present
        expect(subcategory.reload.candidate_label).to eq('Original Candidate')
      end
    end
  end
end

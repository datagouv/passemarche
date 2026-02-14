# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryUpdateService do
  let(:category) do
    create(:category,
      buyer_label: 'Original Buyer',
      candidate_label: 'Original Candidate')
  end

  describe '#perform' do
    context 'with valid params' do
      it 'updates buyer_label only' do
        service = described_class.new(
          category:,
          params: { buyer_label: 'New Buyer' }
        )

        service.perform

        expect(service).to be_success
        expect(category.reload.buyer_label).to eq('New Buyer')
        expect(category.reload.candidate_label).to eq('Original Candidate')
      end

      it 'updates candidate_label only' do
        service = described_class.new(
          category:,
          params: { candidate_label: 'New Candidate' }
        )

        service.perform

        expect(service).to be_success
        expect(category.reload.candidate_label).to eq('New Candidate')
        expect(category.reload.buyer_label).to eq('Original Buyer')
      end

      it 'updates both labels simultaneously' do
        service = described_class.new(
          category:,
          params: { buyer_label: 'New Buyer', candidate_label: 'New Candidate' }
        )

        service.perform

        expect(service).to be_success
        expect(category.reload.buyer_label).to eq('New Buyer')
        expect(category.reload.candidate_label).to eq('New Candidate')
      end

      it 'returns the category as result' do
        service = described_class.new(
          category:,
          params: { buyer_label: 'B', candidate_label: 'C' }
        )

        service.perform

        expect(service.result).to eq(category)
      end
    end

    context 'with blank buyer_label' do
      it 'returns errors and does not save' do
        service = described_class.new(
          category:,
          params: { buyer_label: '', candidate_label: 'Candidate' }
        )

        service.perform

        expect(service).to be_failure
        expect(service.errors[:buyer_label]).to be_present
        expect(category.reload.buyer_label).to eq('Original Buyer')
      end
    end

    context 'with blank candidate_label' do
      it 'returns errors and does not save' do
        service = described_class.new(
          category:,
          params: { buyer_label: 'Buyer', candidate_label: '' }
        )

        service.perform

        expect(service).to be_failure
        expect(service.errors[:candidate_label]).to be_present
        expect(category.reload.candidate_label).to eq('Original Candidate')
      end
    end
  end
end

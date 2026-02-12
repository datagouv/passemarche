# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryLabelHelper, type: :helper do
  describe '#buyer_category_label' do
    context 'when category exists with buyer_label' do
      before { create(:category, key: 'cat_a', buyer_label: 'Buyer A') }

      it 'returns the model label' do
        expect(helper.buyer_category_label('cat_a')).to eq('Buyer A')
      end
    end

    context 'when category does not exist' do
      it 'falls back to I18n' do
        label = helper.buyer_category_label('identite_entreprise')
        expect(label).to be_present
      end
    end

    context 'when category exists but buyer_label is nil' do
      before { create(:category, key: 'cat_no_label', buyer_label: nil) }

      it 'falls back to I18n' do
        label = helper.buyer_category_label('cat_no_label')
        expect(label).to be_present
      end
    end
  end

  describe '#candidate_category_label' do
    context 'when category exists with candidate_label' do
      before { create(:category, key: 'cat_b', candidate_label: 'Candidate B') }

      it 'returns the model label' do
        expect(helper.candidate_category_label('cat_b')).to eq('Candidate B')
      end
    end
  end

  describe '#buyer_subcategory_label' do
    context 'when subcategory exists with buyer_label' do
      before { create(:subcategory, key: 'sub_a', buyer_label: 'Buyer Sub A') }

      it 'returns the model label' do
        expect(helper.buyer_subcategory_label('sub_a')).to eq('Buyer Sub A')
      end
    end
  end

  describe '#candidate_subcategory_label' do
    context 'when subcategory exists with candidate_label' do
      before { create(:subcategory, key: 'sub_b', candidate_label: 'Candidate Sub B') }

      it 'returns the model label' do
        expect(helper.candidate_subcategory_label('sub_b')).to eq('Candidate Sub B')
      end
    end
  end
end

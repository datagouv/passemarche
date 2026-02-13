# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryLabelHelper, type: :helper do
  describe '#category_label' do
    context 'when key is blank' do
      it 'returns a humanized fallback' do
        expect(helper.category_label(nil, role: :buyer)).to eq('')
        expect(helper.category_label('', role: :buyer)).to eq('')
      end
    end

    context 'when an active category exists with a label for the role' do
      before { create(:category, key: 'cat_a', buyer_label: 'Buyer A', candidate_label: 'Candidate A') }

      it 'returns the buyer label' do
        expect(helper.category_label('cat_a', role: :buyer)).to eq('Buyer A')
      end

      it 'returns the candidate label' do
        expect(helper.category_label('cat_a', role: :candidate)).to eq('Candidate A')
      end
    end

    context 'when the category is soft-deleted' do
      before { create(:category, key: 'deleted_cat', buyer_label: 'Should Not Appear', deleted_at: Time.current) }

      it 'falls back to I18n' do
        label = helper.category_label('deleted_cat', role: :buyer)
        expect(label).not_to eq('Should Not Appear')
      end
    end

    context 'when category does not exist' do
      it 'falls back to I18n' do
        label = helper.category_label('identite_entreprise', role: :buyer)
        expect(label).to be_present
      end
    end

    context 'when category exists but label is nil for the role' do
      before { create(:category, key: 'cat_no_label', buyer_label: nil) }

      it 'falls back to I18n' do
        label = helper.category_label('cat_no_label', role: :buyer)
        expect(label).to be_present
      end
    end
  end

  describe '#subcategory_label' do
    context 'when key is blank' do
      it 'returns a humanized fallback' do
        expect(helper.subcategory_label(nil, role: :candidate)).to eq('')
        expect(helper.subcategory_label('', role: :candidate)).to eq('')
      end
    end

    context 'when an active subcategory exists with a label' do
      before { create(:subcategory, key: 'sub_a', buyer_label: 'Buyer Sub A', candidate_label: 'Candidate Sub A') }

      it 'returns the buyer label' do
        expect(helper.subcategory_label('sub_a', role: :buyer)).to eq('Buyer Sub A')
      end

      it 'returns the candidate label' do
        expect(helper.subcategory_label('sub_a', role: :candidate)).to eq('Candidate Sub A')
      end
    end

    context 'when the subcategory is soft-deleted' do
      before { create(:subcategory, key: 'deleted_sub', buyer_label: 'Hidden', deleted_at: Time.current) }

      it 'falls back to I18n' do
        label = helper.subcategory_label('deleted_sub', role: :buyer)
        expect(label).not_to eq('Hidden')
      end
    end
  end

  describe 'N+1 prevention' do
    it 'executes only one query per model class regardless of call count' do
      create(:category, key: 'cat_x', buyer_label: 'X')
      create(:category, key: 'cat_y', buyer_label: 'Y')

      query_count = 0
      callback = lambda { |_name, _start, _finish, _id, payload|
        query_count += 1 if payload[:sql].include?('categories')
      }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        helper.category_label('cat_x', role: :buyer)
        helper.category_label('cat_y', role: :buyer)
        helper.category_label('cat_x', role: :candidate)
      end

      expect(query_count).to eq(1)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'validations' do
    subject { build(:category) }

    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:active_category) { create(:category) }
    let!(:inactive_category) { create(:category, :inactive) }

    describe '.active' do
      it 'returns only active categories' do
        expect(Category.active).to include(active_category)
        expect(Category.active).not_to include(inactive_category)
      end
    end

    describe '.ordered' do
      let!(:second) { create(:category, position: 2) }
      let!(:first) { create(:category, position: 1) }

      it 'orders by position' do
        expect(Category.ordered.to_a.last(2)).to eq([first, second])
      end
    end
  end

  describe '#soft_delete!' do
    let(:category) { create(:category) }
    let!(:subcategory) { create(:subcategory, category:) }

    it 'sets deleted_at on the category' do
      category.soft_delete!
      expect(category.reload.deleted_at).to be_present
    end

    it 'cascades soft delete to subcategories' do
      category.soft_delete!
      expect(subcategory.reload.deleted_at).to be_present
    end
  end

  describe '#active?' do
    it 'returns true when deleted_at is nil' do
      expect(build(:category, deleted_at: nil)).to be_active
    end

    it 'returns false when deleted_at is set' do
      expect(build(:category, :inactive)).not_to be_active
    end
  end
end

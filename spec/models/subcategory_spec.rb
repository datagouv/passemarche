# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subcategory, type: :model do
  describe 'validations' do
    subject { build(:subcategory) }

    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key).scoped_to(:category_id) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:active_subcategory) { create(:subcategory) }
    let!(:inactive_subcategory) { create(:subcategory, :inactive) }

    describe '.active' do
      it 'returns only active subcategories' do
        expect(Subcategory.active).to include(active_subcategory)
        expect(Subcategory.active).not_to include(inactive_subcategory)
      end
    end

    describe '.ordered' do
      let(:category) { create(:category) }
      let!(:second) { create(:subcategory, category:, position: 2) }
      let!(:first) { create(:subcategory, category:, position: 1) }

      it 'orders by position' do
        expect(Subcategory.ordered.where(category:).to_a).to eq([first, second])
      end
    end
  end

  describe 'deletion protection' do
    let(:subcategory) { create(:subcategory) }

    context 'when market_attributes exist' do
      before { create(:market_attribute, subcategory:) }

      it 'prevents destruction' do
        expect { subcategory.destroy }.not_to change(Subcategory, :count)
        expect(subcategory.errors[:base]).to be_present
      end
    end

    context 'when no market_attributes exist' do
      before { subcategory }

      it 'allows destruction' do
        expect { subcategory.destroy }.to change(Subcategory, :count).by(-1)
      end
    end
  end

  describe '#soft_delete!' do
    let(:subcategory) { create(:subcategory) }

    it 'sets deleted_at' do
      subcategory.soft_delete!
      expect(subcategory.reload.deleted_at).to be_present
    end
  end

  describe '#active?' do
    it 'returns true when deleted_at is nil' do
      expect(build(:subcategory, deleted_at: nil)).to be_active
    end

    it 'returns false when deleted_at is set' do
      expect(build(:subcategory, :inactive)).not_to be_active
    end
  end
end

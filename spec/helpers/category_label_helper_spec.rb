# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryLabelHelper do
  let(:helper_instance) { Class.new { include CategoryLabelHelper }.new }

  before do
    category = create(:category, key: 'identity', buyer_label: 'Identité (acheteur)', candidate_label: 'Identité (candidat)')
    create(:subcategory, category:, key: 'basic_info', buyer_label: 'Infos de base (acheteur)', candidate_label: 'Infos de base (candidat)')
  end

  describe '#category_label' do
    it 'returns buyer_label for buyer scope' do
      expect(helper_instance.category_label('identity', scope: :buyer)).to eq('Identité (acheteur)')
    end

    it 'returns candidate_label for candidate scope' do
      expect(helper_instance.category_label('identity', scope: :candidate)).to eq('Identité (candidat)')
    end

    it 'returns humanized key when category not found' do
      expect(helper_instance.category_label('unknown_key', scope: :buyer)).to eq('Unknown key')
    end

    it 'returns default when category not found and default given' do
      expect(helper_instance.category_label('unknown_key', scope: :buyer, default: 'Fallback')).to eq('Fallback')
    end

    it 'returns humanized key for blank key' do
      expect(helper_instance.category_label('', scope: :buyer)).to eq('')
    end
  end

  describe '#subcategory_label' do
    it 'returns buyer_label for buyer scope' do
      expect(helper_instance.subcategory_label('basic_info', scope: :buyer)).to eq('Infos de base (acheteur)')
    end

    it 'returns candidate_label for candidate scope' do
      expect(helper_instance.subcategory_label('basic_info', scope: :candidate)).to eq('Infos de base (candidat)')
    end

    it 'returns humanized key when subcategory not found' do
      expect(helper_instance.subcategory_label('unknown_key', scope: :candidate)).to eq('Unknown key')
    end

    it 'returns default when subcategory not found and default given' do
      expect(helper_instance.subcategory_label('unknown_key', scope: :candidate, default: 'Custom')).to eq('Custom')
    end
  end
end

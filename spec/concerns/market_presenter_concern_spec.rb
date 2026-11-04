# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketPresenterConcern, type: :helper do
  describe '#group_by_subcategory' do
    let(:attr1) { instance_double(MarketAttribute, subcategory_key: 'sub_a', key: 'field_1') }
    let(:attr2) { instance_double(MarketAttribute, subcategory_key: 'sub_a', key: 'field_2') }
    let(:attr3) { instance_double(MarketAttribute, subcategory_key: 'sub_b', key: 'field_3') }

    it 'groups attributes by subcategory and returns keys' do
      result = helper.group_by_subcategory([attr1, attr2, attr3])

      expect(result).to eq(
        'sub_a' => %w[field_1 field_2],
        'sub_b' => %w[field_3]
      )
    end

    it 'returns empty hash for empty input' do
      expect(helper.group_by_subcategory([])).to eq({})
    end
  end

  describe '#field_by_key' do
    let!(:market_attribute) { create(:market_attribute, key: 'test_field') }

    it 'returns market attribute by key' do
      expect(helper.field_by_key('test_field')).to eq(market_attribute)
    end

    it 'accepts symbol key' do
      expect(helper.field_by_key(:test_field)).to eq(market_attribute)
    end

    it 'returns nil for unknown key' do
      expect(helper.field_by_key('unknown')).to be_nil
    end
  end
end

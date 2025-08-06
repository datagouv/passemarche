# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeFilteringService do
  let(:editor) { create(:editor) }
  let!(:supplies_market_type) { create(:market_type, code: 'supplies') }
  let!(:defense_market_type) { create(:market_type, code: 'defense') }
  let!(:works_market_type) { create(:market_type, code: 'works') }

  let!(:supplies_only_attribute) do
    create(:market_attribute, key: 'supplies_field', category_key: 'cat1', subcategory_key: 'sub1').tap do |attr|
      supplies_market_type.market_attributes << attr
    end
  end

  let!(:defense_only_attribute) do
    create(:market_attribute, key: 'defense_field', category_key: 'cat2', subcategory_key: 'sub2').tap do |attr|
      defense_market_type.market_attributes << attr
    end
  end

  let!(:shared_attribute) do
    create(:market_attribute, key: 'shared_field', category_key: 'cat1', subcategory_key: 'sub1').tap do |attr|
      supplies_market_type.market_attributes << attr
      defense_market_type.market_attributes << attr
    end
  end

  let!(:works_attribute) do
    create(:market_attribute, key: 'works_field', category_key: 'cat3', subcategory_key: 'sub3').tap do |attr|
      works_market_type.market_attributes << attr
    end
  end

  let!(:deleted_attribute) do
    create(:market_attribute, key: 'deleted_field', deleted_at: Time.current).tap do |attr|
      supplies_market_type.market_attributes << attr
    end
  end

  describe '.call' do
    context 'with supplies market type only' do
      let(:public_market) { create(:public_market, editor: editor, market_type_codes: ['supplies']) }

      it 'returns attributes available for supplies market type' do
        result = described_class.call(public_market)

        expect(result).to include(supplies_only_attribute, shared_attribute)
        expect(result).not_to include(defense_only_attribute, works_attribute, deleted_attribute)
      end
    end

    context 'with defense market type' do
      let(:public_market) { create(:public_market, editor: editor, market_type_codes: %w[supplies defense]) }

      it 'returns attributes available for defense market type' do
        result = described_class.call(public_market)

        expect(result).to include(defense_only_attribute, shared_attribute)
        expect(result).not_to include(works_attribute, deleted_attribute)
      end
    end

    context 'with multiple market types' do
      let(:public_market) { create(:public_market, editor: editor, market_type_codes: %w[supplies defense]) }

      it 'returns union of attributes from all market types' do
        result = described_class.call(public_market)

        expect(result).to include(supplies_only_attribute, defense_only_attribute, shared_attribute)
        expect(result).not_to include(works_attribute, deleted_attribute)
      end

      it 'returns each attribute only once' do
        result = described_class.call(public_market)

        expect(result.count { |attr| attr.key == 'shared_field' }).to eq(1)
      end
    end

    context 'with ordering' do
      let(:public_market) { create(:public_market, editor: editor, market_type_codes: ['supplies']) }

      before do
        supplies_only_attribute.update!(required: true, category_key: 'b', subcategory_key: 'b')
        shared_attribute.update!(required: false, category_key: 'a', subcategory_key: 'a')
      end

      it 'returns attributes in correct order' do
        result = described_class.call(public_market)

        # Filter to just our test attributes - shared_field comes first because required=false, category=a
        test_attributes = result.select { |attr| %w[supplies_field shared_field].include?(attr.key) }
        expect(test_attributes.map(&:key)).to eq(%w[shared_field supplies_field])
      end
    end

    context 'with deleted attributes' do
      let(:public_market) { create(:public_market, editor: editor, market_type_codes: ['supplies']) }

      it 'excludes deleted attributes' do
        result = described_class.call(public_market)

        expect(result).not_to include(deleted_attribute)
      end
    end

    context 'returns ActiveRecord relation' do
      let(:public_market) { create(:public_market, editor: editor, market_type_codes: ['supplies']) }

      it 'returns an ActiveRecord relation for chaining' do
        result = described_class.call(public_market)

        expect(result).to be_a(ActiveRecord::Relation)
        expect(result.required).to be_a(ActiveRecord::Relation)
      end
    end
  end
end

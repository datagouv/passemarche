# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttribute, type: :model do
  describe 'validations' do
    subject { build(:market_attribute) }

    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
    it { should validate_presence_of(:category_key) }
    it { should validate_presence_of(:subcategory_key) }
    it { should define_enum_for(:input_type).with_values(file_upload: 0, text_input: 1, checkbox: 2) }
  end

  describe 'associations' do
    it { should have_and_belong_to_many(:market_types) }
    it { should have_and_belong_to_many(:public_markets) }
  end

  describe 'scopes' do
    let!(:required_attribute) { create(:market_attribute, required: true) }
    let!(:optional_attribute) { create(:market_attribute, required: false) }
    let!(:api_attribute) { create(:market_attribute, from_api: true) }
    let!(:inactive_attribute) { create(:market_attribute, :inactive) }

    describe '.required' do
      it 'returns only required attributes' do
        expect(MarketAttribute.required).to include(required_attribute)
        expect(MarketAttribute.required).not_to include(optional_attribute)
      end
    end

    describe '.additional' do
      it 'returns only non-required attributes' do
        expect(MarketAttribute.additional).to include(optional_attribute)
        expect(MarketAttribute.additional).not_to include(required_attribute)
      end
    end

    describe '.from_api' do
      it 'returns only attributes from API' do
        expect(MarketAttribute.from_api).to include(api_attribute)
        expect(MarketAttribute.from_api).not_to include(required_attribute)
      end
    end

    describe '.active' do
      it 'returns only active attributes' do
        expect(MarketAttribute.active).to include(required_attribute)
        expect(MarketAttribute.active).not_to include(inactive_attribute)
      end
    end

    describe '.ordered' do
      before { MarketAttribute.delete_all }

      let!(:economic_attr) { create(:market_attribute, required: false, category_key: 'economic', subcategory_key: 'financial', key: 'turnover') }
      let!(:company_attr) { create(:market_attribute, required: true, category_key: 'company', subcategory_key: 'basic', key: 'name') }

      it 'orders by required, category_key, subcategory_key, key' do
        ordered = MarketAttribute.ordered.to_a
        expect(ordered.first).to eq(economic_attr)
        expect(ordered.second).to eq(company_attr)
      end
    end
  end

  describe 'input type predicate methods' do
    describe '#file_upload?' do
      it 'returns true for file_upload input type' do
        attribute = build(:market_attribute, input_type: :file_upload)
        expect(attribute.file_upload?).to be true
      end

      it 'returns false for other input types' do
        attribute = build(:market_attribute, input_type: :text_input)
        expect(attribute.file_upload?).to be false
      end
    end

    describe '#text_input?' do
      it 'returns true for text_input input type' do
        attribute = build(:market_attribute, input_type: :text_input)
        expect(attribute.text_input?).to be true
      end

      it 'returns false for other input types' do
        attribute = build(:market_attribute, input_type: :file_upload)
        expect(attribute.text_input?).to be false
      end
    end

    describe '#checkbox?' do
      it 'returns true for checkbox input type' do
        attribute = build(:market_attribute, input_type: :checkbox)
        expect(attribute.checkbox?).to be true
      end

      it 'returns false for other input types' do
        attribute = build(:market_attribute, input_type: :file_upload)
        expect(attribute.checkbox?).to be false
      end
    end
  end

  describe '#from_authentic_source?' do
    it 'returns true when from_api is true' do
      attribute = build(:market_attribute, from_api: true)
      expect(attribute.from_authentic_source?).to be true
    end

    it 'returns false when from_api is false' do
      attribute = build(:market_attribute, from_api: false)
      expect(attribute.from_authentic_source?).to be false
    end
  end

  describe 'input_types enum' do
    it 'defines the expected input types' do
      expect(MarketAttribute.input_types).to eq({
        'file_upload' => 0,
        'text_input' => 1,
        'checkbox' => 2
      })
    end
  end
end

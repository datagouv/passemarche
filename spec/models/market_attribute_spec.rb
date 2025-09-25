# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttribute, type: :model do
  describe 'validations' do
    subject { build(:market_attribute) }

    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
    it { should validate_presence_of(:category_key) }
    it { should validate_presence_of(:subcategory_key) }
    it {
      should define_enum_for(:input_type).with_values(
        file_upload: 0,
        text_input: 1,
        checkbox: 2,
        textarea: 3,
        email_input: 4,
        phone_input: 5,
        checkbox_with_document: 6,
        file_or_textarea: 7,
        capacite_economique_financiere_chiffre_affaires_global_annuel: 8
      )
    }
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

      let!(:economic_attr) { create(:market_attribute, required: false, category_key: 'test_economic', subcategory_key: 'test_financial', key: 'turnover') }
      let!(:company_attr) { create(:market_attribute, required: true, category_key: 'test_company', subcategory_key: 'test_basic', key: 'name') }

      it 'orders by required, category_key, subcategory_key, key' do
        ordered = MarketAttribute.ordered.to_a
        expect(ordered.first).to eq(economic_attr)
        expect(ordered.second).to eq(company_attr)
      end
    end
  end
end

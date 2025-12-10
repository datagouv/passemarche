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
        capacite_economique_financiere_chiffre_affaires_global_annuel: 8,
        capacite_economique_financiere_effectifs_moyens_annuels: 9,
        presentation_intervenants: 10,
        radio_with_file_and_text: 11,
        realisations_livraisons: 12,
        capacites_techniques_professionnelles_outillage_echantillons: 13,
        url_input: 14,
        radio_with_justification_required: 15,
        inline_file_upload: 16,
        inline_url_input: 17,
        radio_with_justification_optional: 18
      )
    }
  end

  describe 'scopes' do
    let!(:mandatory_attribute) { create(:market_attribute, mandatory: true) }
    let!(:optional_attribute) { create(:market_attribute, mandatory: false) }
    let!(:api_attribute) { create(:market_attribute, api_name: 'Insee', api_key: 'siret') }
    let!(:inactive_attribute) { create(:market_attribute, :inactive) }

    describe '.mandatory' do
      it 'returns only mandatory attributes' do
        expect(MarketAttribute.mandatory).to include(mandatory_attribute)
        expect(MarketAttribute.mandatory).not_to include(optional_attribute)
      end
    end

    describe '.optional' do
      it 'returns only non-mandatory attributes' do
        expect(MarketAttribute.optional).to include(optional_attribute)
        expect(MarketAttribute.optional).not_to include(mandatory_attribute)
      end
    end

    describe '.from_api' do
      it 'returns only attributes with api_name set' do
        expect(MarketAttribute.from_api).to include(api_attribute)
        expect(MarketAttribute.from_api).not_to include(mandatory_attribute)
      end
    end

    describe '.active' do
      it 'returns only active attributes' do
        expect(MarketAttribute.active).to include(mandatory_attribute)
        expect(MarketAttribute.active).not_to include(inactive_attribute)
      end
    end

    describe '.ordered' do
      before { MarketAttribute.delete_all }

      let!(:economic_attr) { create(:market_attribute, mandatory: false, category_key: 'test_economic', subcategory_key: 'test_financial', key: 'turnover') }
      let!(:company_attr) { create(:market_attribute, mandatory: true, category_key: 'test_company', subcategory_key: 'test_basic', key: 'name') }

      it 'orders by mandatory, category_key, subcategory_key, key' do
        ordered = MarketAttribute.ordered.to_a
        expect(ordered.first).to eq(economic_attr)
        expect(ordered.second).to eq(company_attr)
      end
    end
  end

  describe '#from_api?' do
    it 'returns true when api_name is present' do
      attribute = build(:market_attribute, api_name: 'Insee', api_key: 'siret')
      expect(attribute).to be_from_api
    end

    it 'returns false when api_name is nil' do
      attribute = build(:market_attribute, api_name: nil)
      expect(attribute).not_to be_from_api
    end

    it 'returns false when api_name is blank' do
      attribute = build(:market_attribute, api_name: '')
      expect(attribute).not_to be_from_api
    end
  end
end

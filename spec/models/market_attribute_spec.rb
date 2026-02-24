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

    describe '.manual' do
      it 'returns only attributes without api_name' do
        expect(MarketAttribute.manual).to include(mandatory_attribute)
        expect(MarketAttribute.manual).not_to include(api_attribute)
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

    describe '.by_category' do
      let!(:identity_attribute) { create(:market_attribute, category_key: 'identite_entreprise') }
      let!(:exclusion_attribute) { create(:market_attribute, category_key: 'motifs_exclusion') }

      it 'returns only attributes with the specified category' do
        expect(MarketAttribute.by_category('identite_entreprise')).to include(identity_attribute)
        expect(MarketAttribute.by_category('identite_entreprise')).not_to include(exclusion_attribute)
      end
    end

    describe '.by_subcategory' do
      let!(:identification_attribute) { create(:market_attribute, subcategory_key: 'identite_entreprise_identification') }
      let!(:contact_attribute) { create(:market_attribute, subcategory_key: 'identite_entreprise_contact') }

      it 'returns only attributes with the specified subcategory' do
        expect(MarketAttribute.by_subcategory('identite_entreprise_identification')).to include(identification_attribute)
        expect(MarketAttribute.by_subcategory('identite_entreprise_identification')).not_to include(contact_attribute)
      end
    end

    describe '.by_source' do
      it 'returns api attributes when source is :api' do
        expect(MarketAttribute.by_source(:api)).to include(api_attribute)
        expect(MarketAttribute.by_source(:api)).not_to include(mandatory_attribute)
      end

      it 'returns manual attributes when source is :manual' do
        expect(MarketAttribute.by_source(:manual)).to include(mandatory_attribute)
        expect(MarketAttribute.by_source(:manual)).not_to include(api_attribute)
      end

      it 'accepts string arguments' do
        expect(MarketAttribute.by_source('api')).to include(api_attribute)
        expect(MarketAttribute.by_source('manual')).to include(mandatory_attribute)
      end
    end

    describe '.by_market_type' do
      let(:market_type) { create(:market_type) }
      let!(:attribute_with_type) { create(:market_attribute, market_types: [market_type]) }
      let!(:attribute_without_type) { create(:market_attribute) }

      it 'returns only attributes associated with the specified market type' do
        expect(MarketAttribute.by_market_type(market_type.id)).to include(attribute_with_type)
        expect(MarketAttribute.by_market_type(market_type.id)).not_to include(attribute_without_type)
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

  describe '#manual?' do
    it 'returns true when api_name is nil' do
      attribute = build(:market_attribute, api_name: nil)
      expect(attribute).to be_manual
    end

    it 'returns true when api_name is blank' do
      attribute = build(:market_attribute, api_name: '')
      expect(attribute).to be_manual
    end

    it 'returns false when api_name is present' do
      attribute = build(:market_attribute, api_name: 'Insee', api_key: 'siret')
      expect(attribute).not_to be_manual
    end
  end

  describe '#soft_delete!' do
    it 'sets deleted_at and persists' do
      attribute = create(:market_attribute)
      attribute.soft_delete!
      expect(attribute.reload.deleted_at).to be_present
    end

    it 'is idempotent on already-archived record' do
      attribute = create(:market_attribute, deleted_at: 1.day.ago)
      expect { attribute.soft_delete! }.not_to raise_error
      expect(attribute.reload.deleted_at).to be_present
    end
  end

  describe '#active?' do
    it 'returns true when deleted_at is nil' do
      attribute = build(:market_attribute, deleted_at: nil)
      expect(attribute).to be_active
    end

    it 'returns false when deleted_at is present' do
      attribute = build(:market_attribute, deleted_at: Time.current)
      expect(attribute).not_to be_active
    end
  end

  describe '#archived?' do
    it 'returns true when deleted_at is present' do
      attribute = build(:market_attribute, deleted_at: Time.current)
      expect(attribute).to be_archived
    end

    it 'returns false when deleted_at is nil' do
      attribute = build(:market_attribute, deleted_at: nil)
      expect(attribute).not_to be_archived
    end
  end

  describe '#resolved_buyer_name' do
    it 'returns DB value when present' do
      attribute = build(:market_attribute, key: 'test_key', buyer_name: 'Custom Name')
      expect(attribute.resolved_buyer_name).to eq('Custom Name')
    end

    it 'falls back to I18n translation' do
      attribute = build(:market_attribute, key: 'test_key', buyer_name: nil)
      allow(I18n).to receive(:t)
        .with('form_fields.buyer.fields.test_key.name', default: 'Test key')
        .and_return('Translated Name')

      expect(attribute.resolved_buyer_name).to eq('Translated Name')
    end

    it 'falls back to humanized key when I18n missing' do
      attribute = build(:market_attribute, key: 'some_field', buyer_name: nil)
      allow(I18n).to receive(:t)
        .with('form_fields.buyer.fields.some_field.name', default: 'Some field')
        .and_return('Some field')

      expect(attribute.resolved_buyer_name).to eq('Some field')
    end

    it 'ignores blank DB value' do
      attribute = build(:market_attribute, key: 'test_key', buyer_name: '  ')
      allow(I18n).to receive(:t)
        .with('form_fields.buyer.fields.test_key.name', default: 'Test key')
        .and_return('Translated Name')

      expect(attribute.resolved_buyer_name).to eq('Translated Name')
    end
  end

  describe '#resolved_buyer_description' do
    it 'returns DB value when present' do
      attribute = build(:market_attribute, key: 'test_key', buyer_description: 'Custom Desc')
      expect(attribute.resolved_buyer_description).to eq('Custom Desc')
    end

    it 'returns nil when no DB value and no I18n translation' do
      attribute = build(:market_attribute, key: 'test_key', buyer_description: nil)
      allow(I18n).to receive(:t)
        .with('form_fields.buyer.fields.test_key.description', default: nil)
        .and_return(nil)

      expect(attribute.resolved_buyer_description).to be_nil
    end
  end

  describe '#resolved_candidate_name' do
    it 'returns DB value when present' do
      attribute = build(:market_attribute, key: 'test_key', candidate_name: 'Candidate Custom')
      expect(attribute.resolved_candidate_name).to eq('Candidate Custom')
    end

    it 'falls back to I18n translation' do
      attribute = build(:market_attribute, key: 'test_key', candidate_name: nil)
      allow(I18n).to receive(:t)
        .with('form_fields.candidate.fields.test_key.name', default: 'Test key')
        .and_return('Candidate Translated')

      expect(attribute.resolved_candidate_name).to eq('Candidate Translated')
    end
  end

  describe '#resolved_candidate_description' do
    it 'returns DB value when present' do
      attribute = build(:market_attribute, key: 'test_key', candidate_description: 'Candidate Desc')
      expect(attribute.resolved_candidate_description).to eq('Candidate Desc')
    end

    it 'returns nil when no DB value and no I18n translation' do
      attribute = build(:market_attribute, key: 'test_key', candidate_description: nil)
      allow(I18n).to receive(:t)
        .with('form_fields.candidate.fields.test_key.description', default: nil)
        .and_return(nil)

      expect(attribute.resolved_candidate_description).to be_nil
    end
  end

  describe 'CATEGORY_TABS' do
    it 'contains the expected category keys' do
      expected_tabs = %w[
        identite_entreprise
        motifs_exclusion
        capacite_economique_financiere
        capacites_techniques_professionnelles
      ]
      expect(MarketAttribute::CATEGORY_TABS).to eq(expected_tabs)
    end

    it 'is frozen' do
      expect(MarketAttribute::CATEGORY_TABS).to be_frozen
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationService, type: :service do
  let(:service) { described_class.new(market_type: 'supplies', defense_industry: false) }

  describe '#all_fields' do
    it 'returns an array of Field objects' do
      fields = service.all_fields
      expect(fields).to all(be_a(Field))
      expect(fields).not_to be_empty
    end

    it 'loads all configured fields' do
      field_keys = service.all_fields.map(&:key)
      expected_keys = %w[
        unicorn_birth_certificate unicorn_horn_measurement pizza_allergy_declaration
        pineapple_pizza_stance coffee_addiction_level croissant_eating_frequency
        rocket_piloting_license moon_landing_experience ninja_stealth_certificate
        invisible_skill_proof dragon_taming_permit time_travel_authorization
      ]
      expect(field_keys).to match_array(expected_keys)
    end
  end

  describe '#effective_required_fields' do
    context 'with supplies market type and no defense industry' do
      it 'returns correct Field objects' do
        fields = service.effective_required_fields
        field_keys = fields.map(&:key)
        expected_keys = %w[unicorn_birth_certificate pizza_allergy_declaration coffee_addiction_level]
        expect(field_keys).to match_array(expected_keys)
        expect(fields).to all(be_a(Field))
      end
    end

    context 'with defense industry enabled' do
      let(:service) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'includes defense required fields' do
        fields = service.effective_required_fields
        field_keys = fields.map(&:key)
        expect(field_keys).to include('ninja_stealth_certificate', 'invisible_skill_proof')
      end
    end
  end

  describe '#effective_optional_fields' do
    context 'with supplies market type and no defense industry' do
      it 'returns correct Field objects' do
        fields = service.effective_optional_fields
        field_keys = fields.map(&:key)
        expected_keys = %w[rocket_piloting_license ninja_stealth_certificate dragon_taming_permit]
        expect(field_keys).to match_array(expected_keys)
        expect(fields).to all(be_a(Field))
      end
    end

    context 'with defense industry enabled' do
      let(:service) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'includes defense optional fields' do
        fields = service.effective_optional_fields
        field_keys = fields.map(&:key)
        expect(field_keys).to include('time_travel_authorization')
      end
    end
  end

  describe '#field_by_key' do
    it 'returns the correct Field object' do
      field = service.field_by_key('unicorn_birth_certificate')
      expect(field).to be_a(Field)
      expect(field.key).to eq('unicorn_birth_certificate')
      expect(field.type).to eq('document_upload')
    end

    it 'returns nil for non-existent key' do
      field = service.field_by_key('non_existent_field')
      expect(field).to be_nil
    end
  end

  describe '#fields_by_keys' do
    it 'returns Field objects for valid keys' do
      keys = %w[unicorn_birth_certificate pizza_allergy_declaration non_existent]
      fields = service.fields_by_keys(keys)
      expect(fields.size).to eq(2)
      expect(fields.map(&:key)).to match_array(%w[unicorn_birth_certificate pizza_allergy_declaration])
    end
  end
end

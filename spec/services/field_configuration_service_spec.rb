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
      # Get keys from the actual sandbox configuration
      field_keys = service.all_fields.map(&:key)
      expect(field_keys).to include('siret', 'company_name', 'manager_name')
      expect(field_keys.size).to be > 20
    end
  end

  describe '#effective_required_fields' do
    context 'with supplies market type and no defense industry' do
      it 'returns correct Field objects' do
        fields = service.effective_required_fields
        field_keys = fields.map(&:key)
        # Check that we get required fields for supplies market type
        expect(field_keys).to include('siret', 'company_name', 'criminal_conviction')
        expect(field_keys.size).to be > 10
        expect(fields).to all(be_a(Field))
      end
    end

    context 'with defense industry enabled' do
      let(:service) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'includes defense required fields' do
        fields = service.effective_required_fields
        field_keys = fields.map(&:key)
        expect(field_keys).to include('defense_supply_chain')
      end
    end
  end

  describe '#effective_optional_fields' do
    context 'with supplies market type and no defense industry' do
      it 'returns correct Field objects' do
        fields = service.effective_optional_fields
        field_keys = fields.map(&:key)
        # Check that we get optional fields for supplies market type
        expect(field_keys).to include('annual_turnover', 'company_category')
        expect(field_keys.size).to be > 10
        expect(fields).to all(be_a(Field))
      end
    end

    context 'with defense industry enabled' do
      let(:service) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'includes defense optional fields' do
        fields = service.effective_optional_fields
        field_keys = fields.map(&:key)
        expect(field_keys).to include('company_category')
      end
    end
  end

  describe '#field_by_key' do
    it 'returns the correct Field object' do
      field = service.field_by_key('siret')
      expect(field).to be_a(Field)
      expect(field.key).to eq('siret')
      expect(field.type).to eq('text_field')
    end

    it 'returns nil for non-existent key' do
      field = service.field_by_key('non_existent_field')
      expect(field).to be_nil
    end
  end

  describe '#fields_by_keys' do
    it 'returns Field objects for valid keys' do
      keys = %w[siret company_name non_existent]
      fields = service.fields_by_keys(keys)
      expect(fields.size).to eq(2)
      expect(fields.map(&:key)).to match_array(%w[siret company_name])
    end
  end
end

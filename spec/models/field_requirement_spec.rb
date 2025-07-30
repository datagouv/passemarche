# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldRequirement, type: :model do
  let(:field_requirement) { described_class.new(market_type: 'supplies', defense_industry: false) }

  describe 'validations' do
    it 'validates presence of market_type' do
      field_requirement.market_type = nil
      expect(field_requirement).not_to be_valid
      expect(field_requirement.errors[:market_type]).not_to be_empty
    end

    it 'validates inclusion of market_type' do
      field_requirement.market_type = 'invalid'
      expect(field_requirement).not_to be_valid
      expect(field_requirement.errors[:market_type]).not_to be_empty
    end

    it 'is valid with valid market_type' do
      expect(field_requirement).to be_valid
    end
  end

  describe '#required_field_keys' do
    it 'returns required fields for supplies market type without defense' do
      keys = field_requirement.required_field_keys
      expect(keys).to include('siret', 'company_name', 'criminal_conviction')
      expect(keys).not_to include('defense_supply_chain')
    end

    context 'with defense industry enabled' do
      let(:field_requirement) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'includes defense required fields' do
        keys = field_requirement.required_field_keys
        expect(keys).to include('siret', 'company_name', 'defense_supply_chain')
      end
    end
  end

  describe '#optional_field_keys' do
    it 'returns optional fields for supplies market type without defense' do
      keys = field_requirement.optional_field_keys
      expect(keys).to include('annual_turnover', 'prior_contract_breach')
      expect(keys.size).to be > 10
    end

    context 'with defense industry enabled' do
      let(:field_requirement) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'includes defense optional fields' do
        keys = field_requirement.optional_field_keys
        expect(keys).to include('annual_turnover', 'company_category')
        expect(keys.size).to be > 15
      end
    end
  end

  describe '#defense_optional_field_keys' do
    it 'returns empty array when defense industry is false' do
      keys = field_requirement.defense_optional_field_keys
      expect(keys).to be_empty
    end

    context 'with defense industry enabled' do
      let(:field_requirement) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'returns defense optional fields' do
        keys = field_requirement.defense_optional_field_keys
        expect(keys).to include('company_category')
        expect(keys).not_to be_empty
      end
    end
  end

  describe '#field_required?' do
    it 'returns true for required fields' do
      expect(field_requirement.field_required?('siret')).to be true
    end

    it 'returns false for optional fields' do
      expect(field_requirement.field_required?('annual_turnover')).to be false
    end
  end

  describe '#field_optional?' do
    it 'returns true for optional fields' do
      expect(field_requirement.field_optional?('annual_turnover')).to be true
    end

    it 'returns false for required fields' do
      expect(field_requirement.field_optional?('siret')).to be false
    end
  end

  describe '#field_available?' do
    it 'returns true for both required and optional fields' do
      expect(field_requirement.field_available?('siret')).to be true
      expect(field_requirement.field_available?('annual_turnover')).to be true
    end

    it 'returns false for unavailable fields' do
      expect(field_requirement.field_available?('non_existent_field')).to be false
    end
  end

  describe '#field_defense_only?' do
    it 'returns false for non-defense fields when defense is disabled' do
      expect(field_requirement.field_defense_only?('annual_turnover')).to be false
    end

    context 'with defense industry enabled' do
      let(:field_requirement) { described_class.new(market_type: 'supplies', defense_industry: true) }

      it 'returns true for defense-only fields' do
        expect(field_requirement.field_defense_only?('company_category')).to be true
      end

      it 'returns false for non-defense fields' do
        expect(field_requirement.field_defense_only?('siret')).to be false
      end
    end
  end
end

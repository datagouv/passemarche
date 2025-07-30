# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarketPresenter, type: :presenter do
  let(:public_market) { create(:public_market, market_type: 'supplies', defense_industry: false) }
  let(:presenter) { described_class.new(public_market) }

  describe '#required_fields_by_category_and_subcategory' do
    it 'organizes required fields by category and subcategory' do
      result = presenter.required_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)
      expect(result.keys).to include('company_identity', 'exclusion_criteria')

      company_identity = result['company_identity']
      expect(company_identity).to be_a(Hash)
      expect(company_identity['basic_information']).to include('siret')
    end
  end

  describe '#optional_fields_by_category_and_subcategory' do
    it 'organizes optional fields by category and subcategory' do
      result = presenter.optional_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)
      expect(result.keys).to include('economic_capacity', 'technical_capacity')
    end
  end

  describe '#all_fields_by_category_and_subcategory' do
    it 'organizes all fields by category and subcategory' do
      result = presenter.all_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)

      all_field_keys = result.values.flat_map(&:values).flatten
      expect(all_field_keys).to include('siret', 'annual_turnover')
    end
  end

  describe '#should_display_subcategory?' do
    it 'returns true when there are multiple subcategories' do
      subcategories = { 'sub1' => [], 'sub2' => [] }
      expect(presenter.should_display_subcategory?(subcategories)).to be true
    end

    it 'returns false when there is only one subcategory' do
      subcategories = { 'sub1' => [] }
      expect(presenter.should_display_subcategory?(subcategories)).to be false
    end
  end

  describe '#field_by_key' do
    it 'delegates to the service' do
      field = presenter.field_by_key('siret')
      expect(field).to be_a(Field)
      expect(field.key).to eq('siret')
    end
  end

  describe '#source_types' do
    it 'returns localized source types' do
      source_types = presenter.source_types
      expect(source_types).to be_a(Hash)
      expect(source_types).to have_key(:authentic_source)
      expect(source_types).to have_key(:honor_declaration)
    end
  end

  context 'with defense industry enabled' do
    let(:public_market) { create(:public_market, market_type: 'supplies', defense_industry: true) }

    it 'includes defense fields in required and optional collections' do
      required_keys = presenter.required_fields_by_category_and_subcategory.values.flat_map(&:values).flatten
      optional_keys = presenter.optional_fields_by_category_and_subcategory.values.flat_map(&:values).flatten

      expect(required_keys).to include('defense_supply_chain')
      expect(optional_keys).to include('company_category')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarketPresenter, type: :presenter do
  let(:market_type) { create(:market_type, code: 'supplies') }
  let(:public_market) do
    market = build(:public_market)
    market.market_type_codes = [market_type.code]
    market.save!
    market
  end
  let(:presenter) { described_class.new(public_market) }

  let!(:siret_attribute) do
    attr = create(:market_attribute,
      key: 'test_siret',
      category_key: 'company_identity',
      subcategory_key: 'basic_information',
      required: true)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  let!(:criminal_conviction_attribute) do
    attr = create(:market_attribute,
      key: 'test_criminal_conviction',
      category_key: 'exclusion_criteria',
      subcategory_key: 'criminal_convictions',
      required: true)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  let!(:annual_turnover_attribute) do
    attr = create(:market_attribute,
      key: 'test_annual_turnover',
      category_key: 'economic_capacity',
      subcategory_key: 'financial_data',
      required: false)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  let!(:team_presentation_attribute) do
    attr = create(:market_attribute,
      key: 'test_team_presentation',
      category_key: 'technical_capacity',
      subcategory_key: 'workforce',
      required: false)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  describe '#available_required_fields_by_category_and_subcategory' do
    it 'organizes available required fields by category and subcategory' do
      result = presenter.available_required_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)
      expect(result.keys).to include('company_identity', 'exclusion_criteria')

      company_identity = result['company_identity']
      expect(company_identity).to be_a(Hash)
      expect(company_identity['basic_information']).to include('test_siret')
    end
  end

  describe '#available_optional_fields_by_category_and_subcategory' do
    it 'organizes available optional fields by category and subcategory' do
      result = presenter.available_optional_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)
      expect(result.keys).to include('economic_capacity', 'technical_capacity')
    end
  end

  describe '#all_fields_by_category_and_subcategory' do
    it 'organizes all fields by category and subcategory' do
      result = presenter.all_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)

      all_field_keys = result.values.flat_map(&:values).flatten
      expect(all_field_keys).to include('test_siret', 'test_annual_turnover')
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
    it 'returns market attribute by key' do
      field = presenter.field_by_key('test_siret')
      expect(field).to be_a(MarketAttribute)
      expect(field.key).to eq('test_siret')
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
    let(:defense_market_type) { create(:market_type, code: 'defense') }
    let(:defense_public_market) do
      market = create(:public_market)
      market.market_type_codes << defense_market_type.code
      market
    end
    let(:defense_presenter) { described_class.new(defense_public_market) }

    let!(:defense_supply_chain_attribute) do
      attr = create(:market_attribute,
        key: 'test_defense_supply_chain',
        category_key: 'defense_security',
        subcategory_key: 'defense_requirements',
        required: true)
      defense_market_type.market_attributes << attr
      defense_public_market.market_attributes << attr
      attr
    end

    let!(:company_category_attribute) do
      attr = create(:market_attribute,
        key: 'test_company_category',
        category_key: 'company_identity',
        subcategory_key: 'basic_information',
        required: false)
      defense_market_type.market_attributes << attr
      defense_public_market.market_attributes << attr
      attr
    end

    it 'includes defense fields in required and optional collections' do
      required_keys = defense_presenter.available_required_fields_by_category_and_subcategory.values.flat_map(&:values).flatten
      optional_keys = defense_presenter.available_optional_fields_by_category_and_subcategory.values.flat_map(&:values).flatten

      expect(required_keys).to include('test_defense_supply_chain')
      expect(optional_keys).to include('test_company_category')
    end
  end
end

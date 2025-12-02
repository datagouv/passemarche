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
      category_key: 'test_company_identity',
      subcategory_key: 'test_basic_information',
      required: true)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  let!(:criminal_conviction_attribute) do
    attr = create(:market_attribute,
      key: 'test_criminal_conviction',
      category_key: 'test_exclusion_criteria',
      subcategory_key: 'test_criminal_convictions',
      required: true)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  let!(:annual_turnover_attribute) do
    attr = create(:market_attribute,
      key: 'test_annual_turnover',
      category_key: 'test_economic_capacity',
      subcategory_key: 'test_financial_data',
      required: false)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  let!(:team_presentation_attribute) do
    attr = create(:market_attribute,
      key: 'test_team_presentation',
      category_key: 'test_technical_capacity',
      subcategory_key: 'test_workforce',
      required: false)
    market_type.market_attributes << attr
    public_market.market_attributes << attr
    attr
  end

  describe '#available_required_fields_by_category_and_subcategory' do
    it 'organizes available required fields by category and subcategory' do
      result = presenter.available_required_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)
      expect(result.keys).to include('test_company_identity', 'test_exclusion_criteria')

      company_identity = result['test_company_identity']
      expect(company_identity).to be_a(Hash)
      expect(company_identity['test_basic_information']).to include('test_siret')
    end
  end

  describe '#available_optional_fields_by_category_and_subcategory' do
    it 'organizes available optional fields by category and subcategory' do
      result = presenter.available_optional_fields_by_category_and_subcategory
      expect(result).to be_a(Hash)
      expect(result.keys).to include('test_economic_capacity', 'test_technical_capacity')
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

  describe '#display_sidemenu?' do
    it 'returns true when there are multiple subcategories' do
      subcategories = { 'sub1' => [], 'sub2' => [] }
      expect(presenter.display_sidemenu?(subcategories)).to be true
    end

    it 'returns false when there is only one subcategory' do
      subcategories = { 'sub1' => [] }
      expect(presenter.display_sidemenu?(subcategories)).to be false
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

  describe '#wizard_steps' do
    it 'returns steps starting with setup, then categories, ending with summary' do
      steps = presenter.wizard_steps
      expect(steps.first).to eq(:setup)
      expect(steps.last).to eq(:summary)
      expect(steps).to include(:test_company_identity)
      expect(steps).to include(:test_exclusion_criteria)
      expect(steps).to include(:test_economic_capacity)
      expect(steps).to include(:test_technical_capacity)
    end

    it 'returns unique category keys as symbols' do
      steps = presenter.wizard_steps
      category_steps = steps[1..-2]
      expect(category_steps).to all(be_a(Symbol))
      expect(category_steps.uniq).to eq(category_steps)
    end
  end

  describe '#stepper_steps' do
    it 'returns categories plus summary without setup' do
      steps = presenter.stepper_steps
      expect(steps).not_to include(:setup)
      expect(steps.last).to eq(:summary)
      expect(steps).to include(:test_company_identity)
    end
  end

  describe '#parent_category_for' do
    it 'returns the category key when given a category key' do
      expect(presenter.parent_category_for('test_company_identity')).to eq('test_company_identity')
    end

    it 'returns the parent category when given a subcategory key' do
      expect(presenter.parent_category_for('test_basic_information')).to eq('test_company_identity')
    end
  end

  describe '#subcategories_for_category' do
    it 'returns subcategories for a given category' do
      subcategories = presenter.subcategories_for_category('test_company_identity')
      expect(subcategories).to include('test_basic_information')
    end

    it 'returns empty array for blank category' do
      expect(presenter.subcategories_for_category(nil)).to eq([])
      expect(presenter.subcategories_for_category('')).to eq([])
    end
  end

  describe '#required_fields_for_category' do
    it 'returns required fields organized by subcategory' do
      result = presenter.required_fields_for_category('test_company_identity')
      expect(result).to be_a(Hash)
      expect(result['test_basic_information']).to include('test_siret')
    end

    it 'returns empty hash for category with no required fields' do
      result = presenter.required_fields_for_category('test_economic_capacity')
      expect(result).to be_empty
    end
  end

  describe '#optional_fields_for_category' do
    it 'returns optional fields organized by subcategory' do
      result = presenter.optional_fields_for_category('test_economic_capacity')
      expect(result).to be_a(Hash)
      expect(result['test_financial_data']).to include('test_annual_turnover')
    end

    it 'returns empty hash for category with no optional fields' do
      result = presenter.optional_fields_for_category('test_company_identity')
      expect(result).to be_empty
    end
  end

  describe '#optional_fields_for_category?' do
    it 'returns true when category has optional fields' do
      expect(presenter.optional_fields_for_category?('test_economic_capacity')).to be true
    end

    it 'returns false when category has no optional fields' do
      expect(presenter.optional_fields_for_category?('test_company_identity')).to be false
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
        category_key: 'test_defense_security',
        subcategory_key: 'test_defense_requirements',
        required: true)
      defense_market_type.market_attributes << attr
      defense_public_market.market_attributes << attr
      attr
    end

    let!(:company_category_attribute) do
      attr = create(:market_attribute,
        key: 'test_company_category',
        category_key: 'test_company_identity',
        subcategory_key: 'test_basic_information',
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

  describe 'with soft-deleted market attributes' do
    let!(:soft_deleted_attribute) do
      attr = create(:market_attribute,
        key: 'soft_deleted_field',
        category_key: 'test_company_identity',
        subcategory_key: 'test_basic_information',
        required: true,
        deleted_at: 1.day.ago)
      market_type.market_attributes << attr
      public_market.market_attributes << attr
      attr
    end

    it 'excludes soft-deleted attributes from all_fields' do
      result = presenter.all_fields_by_category_and_subcategory
      all_field_keys = result.values.flat_map(&:values).flatten

      expect(all_field_keys).not_to include('soft_deleted_field')
      expect(all_field_keys).to include('test_siret')
    end

    it 'excludes soft-deleted attributes from available_required_fields' do
      result = presenter.available_required_fields_by_category_and_subcategory
      all_field_keys = result.values.flat_map(&:values).flatten

      expect(all_field_keys).not_to include('soft_deleted_field')
    end

    it 'excludes soft-deleted attributes from available_optional_fields' do
      soft_deleted_attribute.update!(required: false)

      result = presenter.available_optional_fields_by_category_and_subcategory
      all_field_keys = result.values.flat_map(&:values).flatten

      expect(all_field_keys).not_to include('soft_deleted_field')
    end
  end
end

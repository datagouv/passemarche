# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationPresenter, type: :presenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:) }

  let!(:identity_attr) do
    create(:market_attribute,
      key: 'company_name',
      category_key: 'identite_entreprise',
      subcategory_key: 'identification',
      public_markets: [public_market])
  end

  let!(:exclusion_attr) do
    create(:market_attribute,
      key: 'exclusion_question',
      category_key: 'exclusion_criteria',
      subcategory_key: 'exclusion_criteria',
      public_markets: [public_market])
  end

  let!(:economic_attr) do
    create(:market_attribute,
      key: 'turnover',
      category_key: 'economic_capacities',
      subcategory_key: 'financial_capacity',
      public_markets: [public_market])
  end

  subject(:presenter) { described_class.new(market_application) }

  describe '#stepper_steps' do
    it 'returns categories plus summary as symbols' do
      expected_steps = %i[identite_entreprise exclusion_criteria economic_capacities summary]
      expect(presenter.stepper_steps).to match_array(expected_steps)
    end

    it 'includes summary as the last step' do
      expect(presenter.stepper_steps.last).to eq(:summary)
    end

    context 'with no market attributes' do
      let(:empty_market) { create(:public_market, :completed, editor:) }
      let(:empty_application) { create(:market_application, public_market: empty_market) }
      let(:empty_presenter) { described_class.new(empty_application) }

      it 'returns only summary' do
        expect(empty_presenter.stepper_steps).to eq([:summary])
      end
    end
  end

  describe '#wizard_steps' do
    it 'returns fixed steps, subcategories, and summary' do
      expected_steps = %i[
        company_identification
        api_data_recovery_status
        market_information
        identification
        exclusion_criteria
        financial_capacity
        summary
      ]
      expect(presenter.wizard_steps).to match_array(expected_steps)
    end

    it 'removes duplicates with uniq' do
      create(:market_attribute,
        key: 'another_field',
        category_key: 'identite_entreprise',
        subcategory_key: 'identification',
        public_markets: [public_market])

      identification_count = presenter.wizard_steps.count(:identification)
      expect(identification_count).to eq(1)
    end
  end

  describe '#parent_category_for' do
    it 'returns correct parent category for a subcategory' do
      expect(presenter.parent_category_for('identification')).to eq('identite_entreprise')
      expect(presenter.parent_category_for('exclusion_criteria')).to eq('exclusion_criteria')
      expect(presenter.parent_category_for('financial_capacity')).to eq('economic_capacities')
    end

    it 'handles symbol input' do
      expect(presenter.parent_category_for(:identification)).to eq('identite_entreprise')
    end

    it 'returns special case for market_information' do
      expect(presenter.parent_category_for('market_information')).to eq('identite_entreprise')
      expect(presenter.parent_category_for(:market_information)).to eq('identite_entreprise')
    end

    it 'returns nil for unknown subcategory' do
      expect(presenter.parent_category_for('unknown_subcategory')).to be_nil
    end

    it 'returns nil for blank input' do
      expect(presenter.parent_category_for('')).to be_nil
      expect(presenter.parent_category_for(nil)).to be_nil
    end
  end

  describe '#subcategories_for_category' do
    it 'returns subcategories for a given category' do
      subcategories = presenter.subcategories_for_category('identite_entreprise')
      expect(subcategories).to include('market_information', 'identification')
    end

    it 'includes market_information first for identite_entreprise' do
      subcategories = presenter.subcategories_for_category('identite_entreprise')
      expect(subcategories.first).to eq('market_information')
    end

    it 'returns subcategories for other categories' do
      subcategories = presenter.subcategories_for_category('economic_capacities')
      expect(subcategories).to eq(['financial_capacity'])
    end

    it 'returns empty array for unknown category' do
      expect(presenter.subcategories_for_category('unknown_category')).to eq([])
    end

    it 'returns empty array for blank input' do
      expect(presenter.subcategories_for_category('')).to eq([])
      expect(presenter.subcategories_for_category(nil)).to eq([])
    end

    it 'orders subcategories consistently by ID order' do
      # Create attributes and test that ordering is consistent with ID order
      attr_z = create(:market_attribute,
        key: 'field_z',
        category_key: 'test_category',
        subcategory_key: 'z_subcategory',
        public_markets: [public_market])

      attr_a = create(:market_attribute,
        key: 'field_a',
        category_key: 'test_category',
        subcategory_key: 'a_subcategory',
        public_markets: [public_market])

      # Test that the order matches the ID order
      subcategories = presenter.subcategories_for_category('test_category')
      expected_order = [attr_z, attr_a].sort_by(&:id).map(&:subcategory_key)
      expect(subcategories).to eq(expected_order)
    end
  end

  describe 'constants' do
    it 'has correct initial wizard steps' do
      expect(described_class::INITIAL_WIZARD_STEPS).to eq(%i[company_identification api_data_recovery_status market_information])
    end

    it 'has correct final wizard step' do
      expect(described_class::FINAL_WIZARD_STEP).to eq(:summary)
    end

    it 'has correct market info parent category' do
      expect(described_class::MARKET_INFO_PARENT_CATEGORY).to eq('identite_entreprise')
    end
  end
end

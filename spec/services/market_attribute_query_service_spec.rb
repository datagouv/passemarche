# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeQueryService do
  let(:category) do
    create(:category, key: 'identity', buyer_label: 'Identite', candidate_label: 'Identite candidat')
  end
  let(:other_category) do
    create(:category, key: 'financial', buyer_label: 'Finance', candidate_label: 'Finance candidat')
  end
  let(:subcategory) do
    create(:subcategory, category:, key: 'basic', buyer_label: 'Info de base', candidate_label: 'Info candidat')
  end
  let(:other_subcategory) do
    create(:subcategory, category: other_category, key: 'perf', buyer_label: 'Performance', candidate_label: 'Perf candidat')
  end
  let(:supplies) { create(:market_type, code: 'supplies') }
  let(:services) { create(:market_type, :services) }

  let!(:attr_manual) do
    create(:market_attribute,
      key: 'company_name', category_key: 'identity', subcategory_key: 'basic',
      subcategory:, buyer_name: 'Nom entreprise').tap { |a| a.market_types << supplies }
  end
  let!(:attr_api) do
    create(:market_attribute, :from_api,
      key: 'turnover', category_key: 'financial', subcategory_key: 'perf',
      subcategory: other_subcategory, buyer_name: 'Chiffre affaires').tap { |a| a.market_types << services }
  end
  let!(:attr_deleted) do
    create(:market_attribute, :inactive,
      key: 'deleted_field', category_key: 'identity', subcategory_key: 'basic',
      subcategory:)
  end

  describe '.call' do
    it 'returns all active attributes with no filters' do
      result = described_class.call(filters: {})

      expect(result).to contain_exactly(attr_manual, attr_api)
    end

    it 'excludes soft-deleted attributes' do
      result = described_class.call(filters: {})

      expect(result).not_to include(attr_deleted)
    end

    it 'filters by category key' do
      result = described_class.call(filters: { category: 'identity' })

      expect(result).to contain_exactly(attr_manual)
    end

    it 'filters by source api' do
      result = described_class.call(filters: { source: 'api' })

      expect(result).to contain_exactly(attr_api)
    end

    it 'filters by source manual' do
      result = described_class.call(filters: { source: 'manual' })

      expect(result).to contain_exactly(attr_manual)
    end

    it 'filters by market type' do
      result = described_class.call(filters: { market_type_id: supplies.id.to_s })

      expect(result).to contain_exactly(attr_manual)
    end

    it 'searches across category buyer_label' do
      result = described_class.call(filters: { query: 'Identite' })

      expect(result).to contain_exactly(attr_manual)
    end

    it 'searches across subcategory buyer_label' do
      result = described_class.call(filters: { query: 'Performance' })

      expect(result).to contain_exactly(attr_api)
    end

    it 'searches across market_attribute key' do
      result = described_class.call(filters: { query: 'company_name' })

      expect(result).to contain_exactly(attr_manual)
    end

    it 'searches across market_attribute buyer_name' do
      result = described_class.call(filters: { query: 'Chiffre' })

      expect(result).to contain_exactly(attr_api)
    end

    it 'combines multiple filters' do
      result = described_class.call(filters: { category: 'identity', source: 'manual' })

      expect(result).to contain_exactly(attr_manual)
    end

    it 'returns empty when combined filters exclude all' do
      result = described_class.call(filters: { category: 'identity', source: 'api' })

      expect(result).to be_empty
    end

    it 'ignores blank filter values' do
      result = described_class.call(filters: { category: '', source: nil, query: '' })

      expect(result).to contain_exactly(attr_manual, attr_api)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeQueryService do
  let(:works_type) { create(:market_type, :works) }
  let(:services_type) { create(:market_type, :services) }

  let!(:identity_attr) do
    create(:market_attribute,
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_identification',
      mandatory: true,
      api_name: 'Insee',
      api_key: 'siret',
      market_types: [works_type, services_type])
  end

  let!(:exclusion_attr) do
    create(:market_attribute,
      category_key: 'motifs_exclusion',
      subcategory_key: 'motifs_fiscales',
      mandatory: false,
      market_types: [works_type])
  end

  let!(:deleted_attr) do
    create(:market_attribute,
      category_key: 'identite_entreprise',
      subcategory_key: 'identite_identification',
      deleted_at: Time.current)
  end

  describe '#perform' do
    it 'returns all active attributes without filters' do
      service = described_class.new
      service.perform
      expect(service.result).to include(identity_attr, exclusion_attr)
      expect(service.result).not_to include(deleted_attr)
    end

    it 'filters by category' do
      service = described_class.new(filters: { category: 'identite_entreprise' })
      service.perform
      expect(service.result).to include(identity_attr)
      expect(service.result).not_to include(exclusion_attr)
    end

    it 'filters by subcategory' do
      service = described_class.new(filters: { subcategory: 'motifs_fiscales' })
      service.perform
      expect(service.result).to include(exclusion_attr)
      expect(service.result).not_to include(identity_attr)
    end

    it 'filters by source api' do
      service = described_class.new(filters: { source: 'api' })
      service.perform
      expect(service.result).to include(identity_attr)
      expect(service.result).not_to include(exclusion_attr)
    end

    it 'filters by source manual' do
      service = described_class.new(filters: { source: 'manual' })
      service.perform
      expect(service.result).to include(exclusion_attr)
      expect(service.result).not_to include(identity_attr)
    end

    it 'filters by mandatory' do
      service = described_class.new(filters: { mandatory: true })
      service.perform
      expect(service.result).to include(identity_attr)
      expect(service.result).not_to include(exclusion_attr)
    end

    it 'filters by market_type_id' do
      service = described_class.new(filters: { market_type_id: services_type.id })
      service.perform
      expect(service.result).to include(identity_attr)
      expect(service.result).not_to include(exclusion_attr)
    end

    it 'combines multiple filters' do
      service = described_class.new(filters: { category: 'identite_entreprise', source: 'api' })
      service.perform
      expect(service.result).to include(identity_attr)
      expect(service.result).not_to include(exclusion_attr)
    end

    it 'ignores blank filters' do
      service = described_class.new(filters: { category: '', source: nil })
      service.perform
      expect(service.result).to include(identity_attr, exclusion_attr)
    end

    it 'is always successful' do
      service = described_class.new
      service.perform
      expect(service).to be_success
    end
  end
end

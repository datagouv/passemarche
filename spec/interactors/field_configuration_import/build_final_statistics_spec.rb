# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport::BuildFinalStatistics, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:context) do
    Interactor::Context.build(statistics: {})
  end

  describe '.call' do
    before do
      MarketAttribute.delete_all
      MarketType.delete_all

      create(:market_attribute, key: 'attr1', deleted_at: nil)
      create(:market_attribute, key: 'attr2', deleted_at: 1.day.ago)
      market_type = create(:market_type, code: 'supplies')

      MarketAttribute.first.market_types << market_type
    end

    it 'calculates and stores final statistics' do
      interactor

      expect(context.statistics).to include(
        total_active_attributes: 1,
        total_market_types: 1,
        total_associations: 1
      )
    end
  end
end

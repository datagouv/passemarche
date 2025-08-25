# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldTranslationImport::BuildTranslationStatistics, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:context) do
    Interactor::Context.build(
      translations:,
      statistics: { fields_processed: 2 }
    )
  end

  let(:translations) do
    {
      buyer: {
        categories: { 'cat1' => 'Category 1', 'cat2' => 'Category 2' },
        subcategories: { 'subcat1' => 'Subcategory 1' },
        fields: { 'field1' => { name: 'Field 1' }, 'field2' => { name: 'Field 2' } }
      },
      candidate: {
        categories: { 'cat1' => 'Category 1' },
        subcategories: {},
        fields: { 'field1' => { name: 'Field 1' } }
      }
    }
  end

  describe '.call' do
    it 'calculates comprehensive translation statistics' do
      interactor

      expect(context.statistics).to include(
        :total_categories,
        :total_subcategories,
        :total_fields
      )
      expect(context.statistics[:total_categories]).to be > 0
      expect(context.statistics[:total_fields]).to be > 0
    end
  end
end

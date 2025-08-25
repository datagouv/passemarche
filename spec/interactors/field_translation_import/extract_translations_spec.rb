# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldTranslationImport::ExtractTranslations, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:context) do
    Interactor::Context.build(
      parsed_rows:,
      statistics: { fields_processed: 0 }
    )
  end

  describe '.call' do
    context 'with valid translation rows' do
      let(:mock_row) do
        double('ParsedRow',
          should_import?: true,
          category_key: 'test_identity',
          subcategory_key: 'test_basic',
          key: 'company_name',
          to_h: {
            'category_acheteur' => 'Buyer Category',
            'subcategory_acheteur' => 'Buyer Subcategory',
            'titre_acheteur' => 'Buyer Field Name',
            'description_acheteur' => 'Buyer Field Description',
            'category_candidat' => 'Candidate Category',
            'subcategory_candidat' => 'Candidate Subcategory',
            'titre_candidat' => 'Candidate Field Name',
            'description_candidat' => 'Candidate Field Description'
          })
      end

      let(:parsed_rows) { [mock_row] }

      it 'extracts translations for both buyer and candidate' do
        interactor

        expect(context.translations).to include(:buyer, :candidate)
        expect(context.translations[:buyer]).to include(:categories, :subcategories, :fields)
        expect(context.translations[:candidate]).to include(:categories, :subcategories, :fields)
        expect(context.statistics[:fields_processed]).to eq(1)
      end
    end

    context 'with non-importable rows' do
      let(:mock_row) do
        double('ParsedRow', should_import?: false, key: 'skipped_field')
      end

      let(:parsed_rows) { [mock_row] }

      it 'skips non-importable rows' do
        interactor

        expect(context.translations[:buyer][:fields]).to be_empty
        expect(context.translations[:candidate][:fields]).to be_empty
        expect(context.statistics[:fields_processed]).to eq(0)
      end
    end
  end
end

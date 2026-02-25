# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport::ImportFieldData, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:supplies_market_type) { create(:market_type, code: 'supplies') }
  let(:context) do
    Interactor::Context.build(
      importable_rows:,
      statistics: { created: 0, updated: 0 }
    )
  end

  before do
    supplies_market_type
  end

  describe '.call' do
    context 'when creating new market attributes' do
      let(:company_name_row) do
        instance_double(CsvRowData,
          key: 'company_name',
          category_key: 'test_identity',
          subcategory_key: 'test_basic',
          category_acheteur: 'Buyer Identity',
          subcategory_acheteur: 'Buyer Basic',
          category_candidat: 'Candidate Identity',
          subcategory_candidat: 'Candidate Basic',
          to_market_attribute_params: {
            input_type: 'text_input',
            category_key: 'test_identity',
            subcategory_key: 'test_basic',
            mandatory: true,
            deleted_at: nil
          },
          applicable_market_types: ['supplies'])
      end

      let(:importable_rows) { [company_name_row] }

      it 'creates new market attributes with correct associations' do
        expect { interactor }.to change(MarketAttribute, :count).by(1)

        market_attribute = MarketAttribute.find_by(key: 'company_name')
        expect(market_attribute.input_type).to eq('text_input')
        expect(market_attribute.mandatory).to be(true)
        expect(market_attribute.market_types).to contain_exactly(supplies_market_type)
        expect(context.statistics[:created]).to eq(1)
      end

      it 'creates category and subcategory records' do
        expect { interactor }
          .to change(Category, :count).by(1)
          .and change(Subcategory, :count).by(1)

        category = Category.find_by(key: 'test_identity')
        expect(category.buyer_label).to eq('Buyer Identity')
        expect(category.candidate_label).to eq('Candidate Identity')

        subcategory = Subcategory.find_by(key: 'test_basic')
        expect(subcategory.buyer_label).to eq('Buyer Basic')
        expect(subcategory.candidate_label).to eq('Candidate Basic')
      end

      it 'links market_attribute to subcategory' do
        interactor
        market_attribute = MarketAttribute.find_by(key: 'company_name')
        expect(market_attribute.subcategory).to eq(Subcategory.find_by(key: 'test_basic'))
      end
    end

    context 'when updating existing market attributes' do
      let!(:existing_attribute) do
        create(:market_attribute, key: 'company_name', category_key: 'old_category')
      end

      let(:company_name_row) do
        instance_double(CsvRowData,
          key: 'company_name',
          category_key: 'new_category',
          subcategory_key: 'test_basic',
          category_acheteur: 'Buyer New',
          subcategory_acheteur: 'Buyer Basic',
          category_candidat: 'Candidate New',
          subcategory_candidat: 'Candidate Basic',
          to_market_attribute_params: {
            input_type: 'text_input',
            category_key: 'new_category',
            subcategory_key: 'test_basic',
            mandatory: true,
            deleted_at: nil
          },
          applicable_market_types: ['supplies'])
      end

      let(:importable_rows) { [company_name_row] }

      it 'updates existing attributes' do
        expect { interactor }.not_to change(MarketAttribute, :count)

        existing_attribute.reload
        expect(existing_attribute.category_key).to eq('new_category')
        expect(context.statistics[:updated]).to eq(1)
      end
    end

    context 'when encountering database errors' do
      let(:company_name_row) do
        instance_double(CsvRowData,
          key: 'company_name',
          category_key: 'test_identity',
          subcategory_key: 'test_basic',
          category_acheteur: 'Buyer Identity',
          subcategory_acheteur: 'Buyer Basic',
          category_candidat: 'Candidate Identity',
          subcategory_candidat: 'Candidate Basic',
          to_market_attribute_params: {
            input_type: nil,
            category_key: 'test_identity',
            subcategory_key: 'test_basic',
            mandatory: true,
            deleted_at: nil
          },
          applicable_market_types: ['supplies'])
      end

      let(:importable_rows) { [company_name_row] }

      it 'fails and rolls back transaction' do
        expect { interactor }.to raise_error(ActiveRecord::RecordInvalid)
        expect do
          interactor
        rescue StandardError
          nil
        end.not_to change(MarketAttribute, :count)
      end
    end
  end
end

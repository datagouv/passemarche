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
          to_market_attribute_params: {
            input_type: 'text_input',
            category_key: 'test_identity',
            subcategory_key: 'test_basic',
            required: true,
            from_api: false,
            deleted_at: nil
          },
          applicable_market_types: ['supplies'])
      end

      let(:importable_rows) { [company_name_row] }

      it 'creates new market attributes with correct associations' do
        expect { interactor }.to change(MarketAttribute, :count).by(1)

        market_attribute = MarketAttribute.find_by(key: 'company_name')
        expect(market_attribute.input_type).to eq('text_input')
        expect(market_attribute.required).to be(true)
        expect(market_attribute.market_types).to contain_exactly(supplies_market_type)
        expect(context.statistics[:created]).to eq(1)
      end
    end

    context 'when updating existing market attributes' do
      let!(:existing_attribute) do
        create(:market_attribute, key: 'company_name', category_key: 'old_category')
      end

      let(:company_name_row) do
        instance_double(CsvRowData,
          key: 'company_name',
          to_market_attribute_params: {
            input_type: 'text_input',
            category_key: 'new_category',
            subcategory_key: 'test_basic',
            required: true,
            from_api: false,
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
          to_market_attribute_params: {
            input_type: nil,
            category_key: 'test_identity',
            subcategory_key: 'test_basic',
            required: true,
            from_api: false,
            deleted_at: nil
          },
          applicable_market_types: ['supplies'])
      end

      let(:importable_rows) { [company_name_row] }

      it 'fails and rolls back transaction' do
        expect { interactor }.to raise_error(ActiveRecord::StatementInvalid)
        expect do
          interactor
        rescue StandardError
          nil
        end.not_to change(MarketAttribute, :count)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport::FilterImportableRows, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:context) do
    Interactor::Context.build(
      parsed_rows: parsed_rows,
      statistics: { skipped: 0, processed: 0 }
    )
  end

  describe '.call' do
    context 'with mixed valid and invalid rows' do
      let(:valid_row) { instance_double(CsvRowData, importable?: true, should_import?: true, key: 'valid_field') }
      let(:invalid_row) { instance_double(CsvRowData, importable?: false, should_import?: false, key: 'invalid_field') }
      let(:parsed_rows) { [valid_row, invalid_row] }

      it 'filters out non-importable rows and updates statistics' do
        interactor

        expect(context.importable_rows).to contain_exactly(valid_row)
        expect(context.statistics[:skipped]).to eq(1)
      end
    end

    context 'with all valid rows' do
      let(:row1) { instance_double(CsvRowData, importable?: true, should_import?: true, key: 'field1') }
      let(:row2) { instance_double(CsvRowData, importable?: true, should_import?: true, key: 'field2') }
      let(:parsed_rows) { [row1, row2] }

      it 'keeps all rows and does not increment skip count' do
        interactor

        expect(context.importable_rows).to contain_exactly(row1, row2)
        expect(context.statistics[:skipped]).to eq(0)
      end
    end
  end
end

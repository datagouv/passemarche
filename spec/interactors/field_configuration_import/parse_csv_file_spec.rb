# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport::ParseCsvFile, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:csv_file_path) { Rails.root.join('spec/fixtures/parse_test.csv') }
  let(:context) do
    Interactor::Context.build(
      csv_file_path:,
      statistics: { processed: 0, skipped: 0 }
    )
  end

  before do
    FileUtils.mkdir_p(File.dirname(csv_file_path))
  end

  after do
    FileUtils.rm_f(csv_file_path)
  end

  describe '.call' do
    context 'with valid CSV structure' do
      before do
        csv_content = <<~CSV
          ,,,,,,
          ,,,,,,
          ,,,,,,
          key,category_key,subcategory_key,type,import,apifiable,services,fournitures,travaux,défense
          company_name,identity,basic,texte,oui,non,oui,oui,oui,non
          business_turnover,financial,performance,texte,oui,non,non,oui,non,non
        CSV
        File.write(csv_file_path, csv_content)
      end

      it 'parses CSV and creates row data objects' do
        interactor

        expect(context.csv_lines.size).to eq(6)
        expect(context.headers).to eq(%w[key category_key subcategory_key type import apifiable services fournitures travaux défense])
        expect(context.parsed_rows.size).to eq(2)

        first_row = context.parsed_rows.first
        expect(first_row.key).to eq('company_name')
        expect(first_row.type).to eq('texte')
      end
    end

    context 'with malformed CSV data' do
      before do
        csv_content = <<~CSV
          ,,,,,,
          ,,,,,,
          ,,,,,,
          key,type,category_key,subcategory_key,import
          valid_row,texte,identity,basic,oui
          malformed,"unclosed quote
          another_valid,texte,identity,basic,oui
        CSV
        File.write(csv_file_path, csv_content)
      end

      it 'handles malformed rows gracefully' do
        interactor

        expect(context.parsed_rows.size).to eq(2)
        expect(context.parsed_rows.map(&:key)).to contain_exactly('valid_row', 'another_valid')
        expect(context.statistics[:malformed_rows].size).to eq(1)
      end
    end

    context 'with insufficient CSV structure' do
      before do
        csv_content = <<~CSV
          line1
          line2
          line3
        CSV
        File.write(csv_file_path, csv_content)
      end

      it 'fails with appropriate error' do
        expect(interactor).to be_failure
        expect(interactor.message).to eq('Invalid CSV: expected at least 5 lines')
      end
    end
  end
end

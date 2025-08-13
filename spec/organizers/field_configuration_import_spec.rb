# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport, type: :organizer do
  let(:csv_file_path) { Rails.root.join('spec/fixtures/field_configuration_test.csv') }
  let(:context) { { csv_file_path: csv_file_path } }

  before do
    MarketAttribute.delete_all
    MarketType.delete_all
    create(:market_type, code: 'supplies')
    create(:market_type, code: 'services')
  end

  after do
    FileUtils.rm_f(csv_file_path)
  end

  describe '.call' do
    context 'with valid CSV file and data' do
      before do
        csv_content = <<~CSV
          ,,,,,,
          ,,,,,,
          ,,,,,,
          key,category_key,subcategory_key,type,import,apifiable,obligatoire,services,fournitures,travaux,défense
          company_name,identity,basic,texte,oui,non,oui,oui,oui,oui,non
          business_turnover,financial,performance,texte,oui,non,non,non,oui,non,non
        CSV

        FileUtils.mkdir_p(File.dirname(csv_file_path))
        File.write(csv_file_path, csv_content)
      end

      it 'successfully processes the complete import workflow' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.statistics[:processed]).to eq(2)
        expect(result.statistics[:created]).to eq(2)
        expect(result.statistics).to include(:total_active_attributes, :total_market_types)

        expect(MarketAttribute.count).to eq(2)
        company_name = MarketAttribute.find_by(key: 'company_name')
        expect(company_name.market_types.pluck(:code)).to include('services', 'supplies')
      end
    end

    context 'with invalid CSV file path' do
      let(:csv_file_path) { '/nonexistent/file.csv' }

      it 'fails at validation step with appropriate error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('CSV file not found')
      end
    end

    context 'with malformed CSV content' do
      before do
        csv_content = "invalid,csv\nstructure"
        FileUtils.mkdir_p(File.dirname(csv_file_path))
        File.write(csv_file_path, csv_content)
      end

      it 'fails at parsing step with appropriate error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Invalid CSV')
      end
    end
  end
end

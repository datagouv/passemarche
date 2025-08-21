# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldTranslationImport, type: :organizer do
  let(:csv_file_path) { Rails.root.join('spec/fixtures/translation_test.csv') }
  let(:temp_translation_file) { Rails.root.join('tmp/test_form_fields.fr.yml') }
  let(:mock_file_writer) { double('FileWriter') }
  let(:context) do
    {
      csv_file_path: csv_file_path,
      translation_file_path: temp_translation_file,
      file_writer: mock_file_writer
    }
  end

  before do
    allow(mock_file_writer).to receive(:write)
  end

  after do
    FileUtils.rm_f(csv_file_path)
    FileUtils.rm_f(temp_translation_file)
  end

  describe '.call' do
    context 'with valid translation CSV' do
      before do
        csv_content = <<~CSV
          ,,,,,,
          ,,,,,,
          ,,,,,,
          clé technique,category_key,subcategory_key,category_acheteur,subcategory_acheteur,titre_acheteur,description_acheteur,obligatoire,category_candidat,subcategory_candidat,titre_candidat,description_candidat,type,import
          company_name,identity,basic,Identité,Information de base,Nom de l'entreprise,Raison sociale,oui,Identité,Info de base,Nom entreprise,Raison sociale de l'entreprise,texte,oui
        CSV

        FileUtils.mkdir_p(File.dirname(csv_file_path))
        File.write(csv_file_path, csv_content)
      end

      it 'successfully processes the complete translation workflow' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.translations).to include(:buyer, :candidate)
        expect(result.statistics).to include(:fields_processed, :total_categories, :total_subcategories)
        expect(result.statistics[:fields_processed]).to eq(1)
      end
    end

    context 'with invalid CSV file' do
      let(:csv_file_path) { '/nonexistent/translation_file.csv' }

      it 'fails at validation step' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('CSV file not found')
      end
    end

    context 'with malformed CSV structure' do
      before do
        csv_content = "invalid,csv\nstructure"
        FileUtils.mkdir_p(File.dirname(csv_file_path))
        File.write(csv_file_path, csv_content)
      end

      it 'fails at parsing step' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Invalid CSV')
      end
    end
  end
end

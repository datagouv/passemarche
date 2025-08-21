# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldTranslationImport::UpdateTranslationFile, type: :interactor do
  let(:mock_file_writer) { double('FileWriter') }
  let(:temp_file_path) { Rails.root.join('tmp/test_translations.yml') }
  let(:test_translations) do
    {
      buyer: {
        categories: { identity: 'Identité' },
        subcategories: { basic: 'Information de base' },
        fields: { company_name: { name: 'Nom de l\'entreprise' } }
      },
      candidate: {
        categories: { identity: 'Identité' },
        subcategories: { basic: 'Info de base' },
        fields: { company_name: { name: 'Nom entreprise' } }
      }
    }
  end
  let(:context) do
    Interactor::Context.build(
      translations: test_translations,
      translation_file_path: temp_file_path,
      file_writer: mock_file_writer,
      statistics: {}
    )
  end

  describe '.call' do
    context 'when translations are provided' do
      it 'writes the translation file using the injected file writer' do
        expect(mock_file_writer).to receive(:write).with(temp_file_path, kind_of(String))

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.statistics[:translation_file_updated]).to be true
        expect(result.translation_file_path).to eq(temp_file_path)
      end

      it 'generates proper YAML content with header' do
        written_content = nil
        allow(mock_file_writer).to receive(:write) do |_path, content|
          written_content = content
        end

        described_class.call(context)

        expect(written_content).to include('# Form Fields French Translations')
        expect(written_content).to include('# Auto-generated from CSV import')
        expect(written_content).to include('fr:')
        expect(written_content).to include('form_fields:')
      end
    end

    context 'when no translations are provided' do
      let(:context) do
        Interactor::Context.build(
          translations: nil,
          translation_file_path: temp_file_path,
          file_writer: mock_file_writer,
          statistics: {}
        )
      end

      it 'does not write anything' do
        expect(mock_file_writer).not_to receive(:write)

        result = described_class.call(context)

        expect(result).to be_success
      end
    end

    context 'when file writing fails' do
      it 'raises the error naturally' do
        allow(mock_file_writer).to receive(:write).and_raise(StandardError, 'Disk full')

        expect { described_class.call(context) }.to raise_error(StandardError, 'Disk full')
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport::ValidateCsvFile, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:context) { Interactor::Context.build(csv_file_path:) }

  describe '.call' do
    context 'when CSV file exists' do
      let(:csv_file_path) { Rails.root.join('spec/fixtures/existing_file.csv') }

      before do
        FileUtils.mkdir_p(File.dirname(csv_file_path))
        File.write(csv_file_path, "test,content\n")
      end

      after do
        FileUtils.rm_f(csv_file_path)
      end

      it 'succeeds' do
        expect(interactor).to be_success
      end

      it 'does not modify the context' do
        original_keys = context.to_h.keys
        interactor
        expect(context.to_h.keys).to eq(original_keys)
      end
    end

    context 'when CSV file does not exist' do
      let(:csv_file_path) { '/nonexistent/directory/file.csv' }

      it 'fails' do
        expect(interactor).to be_failure
      end

      it 'provides appropriate error message' do
        expect(interactor.message).to eq("CSV file not found: #{csv_file_path}")
      end

      it 'does not add any other context data' do
        interactor
        expect(context.to_h.keys).to contain_exactly(:csv_file_path, :message)
      end
    end

    context 'when CSV file path is nil' do
      let(:csv_file_path) { nil }

      it 'fails' do
        expect(interactor).to be_failure
      end

      it 'provides appropriate error message' do
        expect(interactor.message).to eq('CSV file not found: ')
      end
    end

    context 'when CSV file path is empty string' do
      let(:csv_file_path) { '' }

      it 'fails' do
        expect(interactor).to be_failure
      end

      it 'provides appropriate error message' do
        expect(interactor.message).to eq('CSV file not found: ')
      end
    end

    context 'when CSV file exists but is a directory' do
      let(:csv_file_path) { Rails.root.join('spec/fixtures/') }

      it 'fails' do
        expect(interactor).to be_failure
      end

      it 'provides appropriate error message' do
        expect(interactor.message).to eq("CSV file not found: #{csv_file_path}")
      end
    end
  end
end

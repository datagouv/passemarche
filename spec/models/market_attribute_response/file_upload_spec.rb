# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileUpload, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'file_upload') }
  let(:file_response) { build(:market_attribute_response_file_upload, market_application:, market_attribute:) }

  describe 'constants' do
    it 'defines MAX_FILE_SIZE' do
      expect(MarketAttributeResponse::FileUpload::MAX_FILE_SIZE).to eq(100.megabytes)
    end

    it 'defines ALLOWED_CONTENT_TYPES' do
      expect(MarketAttributeResponse::FileUpload::ALLOWED_CONTENT_TYPES).to include('application/pdf')
      expect(MarketAttributeResponse::FileUpload::ALLOWED_CONTENT_TYPES).to include('image/jpeg')
      expect(MarketAttributeResponse::FileUpload::ALLOWED_CONTENT_TYPES).to include('application/msword')
    end
  end

  describe 'file accessor' do
    it 'returns nil when value is empty' do
      file_response.value = {}
      expect(file_response.file).to be_nil
    end

    it 'returns nil when value is nil' do
      file_response.value = nil
      expect(file_response.file).to be_nil
    end

    it 'returns the file data when present' do
      file_data = { 'name' => 'test.pdf', 'content_type' => 'application/pdf', 'size' => 1024 }
      file_response.value = { 'file' => file_data }
      expect(file_response.file).to eq(file_data)
    end

    context 'when setting file' do
      let(:mock_file) { double('file', original_filename: 'test.pdf', content_type: 'application/pdf', size: 1024, present?: true) }

      it 'sets the file metadata' do
        file_response.file = mock_file
        expected_value = {
          'file' => {
            'name' => 'test.pdf',
            'content_type' => 'application/pdf',
            'size' => 1024
          }
        }
        expect(file_response.value).to eq(expected_value)
      end

      it 'preserves other values when setting file' do
        file_response.value = { 'other' => 'data' }
        file_response.file = mock_file
        expect(file_response.value['other']).to eq('data')
        expect(file_response.value['file']).to be_present
      end
    end
  end

  describe 'JSON schema validation' do
    let(:valid_file_data) do
      {
        'file' => {
          'name' => 'test.pdf',
          'content_type' => 'application/pdf',
          'size' => 1024
        }
      }
    end

    context 'for new records' do
      it 'skips JSON schema validation' do
        file_response.value = { 'file' => { 'name' => 'test.exe', 'content_type' => 'invalid', 'size' => 'invalid' } }
        file_response.valid?
        # Should not have JSON schema errors (validation skipped for new records)
        expect(file_response.errors[:value]).to be_empty
      end

      it 'allows nil value' do
        file_response.value = nil
        file_response.valid?
        expect(file_response.errors[:value]).to be_empty
      end
    end

    context 'for persisted records' do
      before do
        # Save the record to make it persisted
        file_response.save!(validate: false)
        file_response.reload
      end

      it 'validates correct structure' do
        file_response.value = valid_file_data
        expect(file_response).to be_valid
      end

      it 'validates all required file fields' do
        file_response.value = {
          'file' => {
            'name' => 'document.docx',
            'content_type' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'size' => 2048
          }
        }
        expect(file_response).to be_valid
      end

      it 'rejects missing file object' do
        file_response.value = {}
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects nil value' do
        file_response.value = nil
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects file with missing name' do
        file_response.value = {
          'file' => {
            'content_type' => 'application/pdf',
            'size' => 1024
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects file with missing content_type' do
        file_response.value = {
          'file' => {
            'name' => 'test.pdf',
            'size' => 1024
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects file with missing size' do
        file_response.value = {
          'file' => {
            'name' => 'test.pdf',
            'content_type' => 'application/pdf'
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects non-allowed content types' do
        file_response.value = {
          'file' => {
            'name' => 'virus.exe',
            'content_type' => 'application/x-executable',
            'size' => 1024
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects files that are too large' do
        file_response.value = {
          'file' => {
            'name' => 'huge.pdf',
            'content_type' => 'application/pdf',
            'size' => 101.megabytes
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects zero-size files' do
        file_response.value = {
          'file' => {
            'name' => 'empty.pdf',
            'content_type' => 'application/pdf',
            'size' => 0
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end

      it 'rejects additional properties in file object' do
        file_response.value = {
          'file' => {
            'name' => 'test.pdf',
            'content_type' => 'application/pdf',
            'size' => 1024,
            'extra' => 'field'
          }
        }
        expect(file_response).not_to be_valid
        expect(file_response.errors[:value]).to be_present
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileAttachable, type: :model do
  let(:file_upload_response) { create(:market_attribute_response_file_upload) }

  describe 'attachment setup' do
    it 'has many attached documents' do
      expect(file_upload_response).to respond_to(:documents)
      expect(file_upload_response.documents).to be_an(ActiveStorage::Attached::Many)
    end
  end

  describe 'constants' do
    it 'defines MAX_FILE_SIZE as 100 megabytes' do
      expect(described_class::MAX_FILE_SIZE).to eq(100.megabytes)
    end

    it 'defines ALLOWED_CONTENT_TYPES with expected values' do
      expect(described_class::ALLOWED_CONTENT_TYPES).to include(
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/gif',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      )
    end
  end

  describe '#files=' do
    context 'with blank input' do
      it 'does nothing when input is nil' do
        expect { file_upload_response.files = nil }.not_to change { file_upload_response.documents.count }
      end

      it 'does nothing when input is empty array' do
        expect { file_upload_response.files = [] }.not_to change { file_upload_response.documents.count }
      end

      it 'skips blank values in array' do
        expect { file_upload_response.files = ['', nil] }.not_to change { file_upload_response.documents.count }
      end
    end
  end

  describe 'file validations' do
    subject(:response) { create(:market_attribute_response_file_upload) }

    describe 'content type validation' do
      it 'accepts PDF files' do
        attach_file_with_content_type(response, 'application/pdf')
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'accepts JPEG images' do
        attach_file_with_content_type(response, 'image/jpeg')
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'accepts PNG images' do
        attach_file_with_content_type(response, 'image/png')
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'accepts Word documents' do
        attach_file_with_content_type(response, 'application/msword')
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'accepts Excel spreadsheets' do
        attach_file_with_content_type(response, 'application/vnd.ms-excel')
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'rejects disallowed content types' do
        attach_file_with_content_type(response, 'application/zip')
        response.valid?
        expect(response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
      end
    end

    describe 'file size validation' do
      it 'accepts files within size limit' do
        stub_document_with_size(response, 50.megabytes)
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'rejects files exceeding size limit' do
        stub_document_with_size(response, 101.megabytes)
        response.valid?
        expect(response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
      end
    end

    describe 'file name validation' do
      it 'accepts valid filenames' do
        stub_document_with_name(response, 'document.pdf')
        response.valid?
        expect(response.errors[:documents]).to be_empty
      end

      it 'rejects filenames exceeding 255 characters' do
        long_name = "#{'a' * 256}.pdf"
        stub_document_with_name(response, long_name)
        response.valid?
        expect(response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
      end
    end
  end

  describe 'error handling for direct uploads' do
    subject(:response) { create(:market_attribute_response_file_upload) }

    it 'handles InvalidSignature error gracefully' do
      allow(ActiveStorage::Blob).to receive(:find_signed!).and_raise(ActiveSupport::MessageVerifier::InvalidSignature)

      result = response.send(:attach_direct_upload, 'invalid_signed_id', {})

      expect(result).to be false
      expect(response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end

    it 'handles RecordNotFound error gracefully' do
      allow(ActiveStorage::Blob).to receive(:find_signed!).and_raise(ActiveRecord::RecordNotFound)

      result = response.send(:attach_direct_upload, 'missing_blob_id', {})

      expect(result).to be false
      expect(response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end

    it 'handles IntegrityError gracefully' do
      allow(ActiveStorage::Blob).to receive(:find_signed!).and_raise(ActiveStorage::IntegrityError)

      result = response.send(:attach_direct_upload, 'corrupted_blob_id', {})

      expect(result).to be false
      expect(response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end
  end

  describe 'traditional upload handling' do
    subject(:response) { create(:market_attribute_response_file_upload) }

    it 'attaches ActionDispatch::Http::UploadedFile' do
      tempfile = Tempfile.new(['test', '.pdf'])
      tempfile.write('PDF content')
      tempfile.rewind

      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile:,
        filename: 'test.pdf',
        type: 'application/pdf'
      )

      response.send(:attach_traditional_upload, uploaded_file, {})
      expect(response.documents.count).to eq(1)
      expect(response.documents.last.filename.to_s).to eq('test.pdf')

      tempfile.close
      tempfile.unlink
    end
  end

  private

  def attach_file_with_content_type(response, content_type)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('test content'),
      filename: 'test.pdf',
      content_type:
    )
    response.documents.attach(blob)
  end

  def stub_document(content_type: 'application/pdf', size: 1000, filename: 'test.pdf')
    doc = double('ActiveStorage::Attached::One')
    allow(doc).to receive_messages(
      content_type:,
      byte_size: size,
      filename: ActiveStorage::Filename.new(filename)
    )
    doc
  end

  def stub_document_with_size(response, size)
    allow(response).to receive(:documents).and_return([stub_document(size:)])
  end

  def stub_document_with_name(response, filename)
    allow(response).to receive(:documents).and_return([stub_document(filename:)])
  end
end

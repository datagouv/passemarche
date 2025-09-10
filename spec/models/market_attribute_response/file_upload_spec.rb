require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileUpload, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'file_upload') }
  let(:file_response) { build(:market_attribute_response_file_upload) }

  describe 'constants' do
    it 'defines MAX_FILE_SIZE' do
      expect(described_class::MAX_FILE_SIZE).to eq(100.megabytes)
    end

    it 'defines ALLOWED_CONTENT_TYPES' do
      expect(described_class::ALLOWED_CONTENT_TYPES).to include('application/pdf')
      expect(described_class::ALLOWED_CONTENT_TYPES).to include('image/jpeg')
    end
  end

  describe 'documents attachment' do
    let(:file1) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy pdf content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
    end
    let(:file2) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy jpg content'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      )
    end

    it 'attaches multiple files' do
      file_response.documents.attach([file1, file2])
      expect(file_response.documents.count).to eq(2)
      expect(file_response.documents.first.filename.to_s).to eq('test.pdf')
      expect(file_response.documents.last.filename.to_s).to eq('test.jpg')
    end
  end

  describe 'documents validations' do
    it 'requires documents if none attached' do
      file_response.documents = []
      file_response.valid?
      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.required'))
    end

    it 'rejects blank content_type' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: 'test.pdf',
        content_type: ''
      )
      allow(blob).to receive(:content_type).and_return(nil)
      file_response.documents.attach(blob)
      file_response.valid?

      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.required'))
    end

    it 'rejects non-allowed content types' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: 'test.exe',
        content_type: 'application/x-msdownload'
      )
      file_response.documents.attach(blob)
      file_response.valid?

      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end

    it 'rejects files that are too large' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('a' * 101.megabytes),
        filename: 'big.pdf',
        content_type: 'application/pdf'
      )
      file_response.documents.attach(blob)
      file_response.valid?

      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end

    it 'rejects zero-size files' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(''),
        filename: 'empty.pdf',
        content_type: 'application/pdf'
      )
      allow(blob).to receive(:byte_size).and_return(0)
      file_response.documents.attach(blob)
      file_response.valid?

      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end

    it 'rejects file with missing name' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: '',
        content_type: 'application/pdf'
      )
      file_response.documents.attach(blob)
      file_response.valid?

      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.required'))
    end

    it 'rejects file with too long name' do
      long_name = "#{'a' * 256}.pdf"
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: long_name,
        content_type: 'application/pdf'
      )
      file_response.documents.attach(blob)
      file_response.valid?

      expect(file_response.errors[:documents]).to include(I18n.t('activerecord.errors.json_schema.invalid'))
    end

    it 'accepts valid files' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: 'valid.pdf',
        content_type: 'application/pdf'
      )
      file_response.documents.attach(blob)

      expect(file_response.valid?).to be true
      expect(file_response.errors[:documents]).to be_empty
    end
  end

  describe 'metadata' do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: 'test.png',
        content_type: 'image/png'
      )
    end

    before { file_response.documents.attach(blob) }

    it 'stores the correct metadata in ActiveStorage' do
      expect(file_response.documents.first.filename.to_s).to eq('test.png')
      expect(file_response.documents.first.content_type).to eq('image/png')
      expect(file_response.documents.first.byte_size).to eq(13)
    end
  end
end

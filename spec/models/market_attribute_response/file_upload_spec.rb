require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileUpload, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'file_upload') }
  let(:file_response) { build(:market_attribute_response_file_upload) }

  describe 'configuration' do
    it 'uses centralized max file size' do
      expect(described_class.max_file_size).to eq(Rails.configuration.file_upload.max_size)
    end

    it 'uses centralized allowed content types' do
      expect(described_class.allowed_content_types).to include('application/pdf')
      expect(described_class.allowed_content_types).to include('image/jpeg')
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
    it 'allows no documents attached' do
      file_response.documents = []
      expect(file_response).to be_valid
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

    it 'accepts valid files that have been scanned' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('dummy content'),
        filename: 'valid.pdf',
        content_type: 'application/pdf'
      )
      blob.metadata['scan_safe'] = true
      blob.metadata['scanned_at'] = Time.current.iso8601
      blob.save!

      file_response.documents.attach(blob)

      expect(file_response.valid?).to be true
      expect(file_response.errors[:documents]).to be_empty
    end

    context 'security scanning' do
      it 'blocks submission when files are still being scanned' do
        file_response = create(:market_attribute_response_file_upload,
          market_application:,
          market_attribute:)

        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('dummy content'),
          filename: 'scanning.pdf',
          content_type: 'application/pdf'
        )
        # No scan_safe in metadata = scanning in progress
        file_response.documents.attach(blob)

        market_application.market_attribute_responses.reload

        # Validation during upload should pass
        expect(file_response.valid?).to be true

        # Validation during intermediate form steps should also pass
        context = file_response.market_attribute.subcategory_key
        expect(market_application.valid?(context)).to be true

        # Validation at summary should fail if scan not complete
        is_valid = market_application.valid?(:summary)
        expect(is_valid).to be false
        # Errors are propagated to the parent market_application
        expect(market_application.errors[:base]).to include(match(/scan de sécurité est en cours/))
      end

      it 'rejects files with malware detected' do
        file_response = create(:market_attribute_response_file_upload,
          market_application:,
          market_attribute:)

        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('dummy content'),
          filename: 'infected.pdf',
          content_type: 'application/pdf'
        )
        blob.metadata['scan_safe'] = false
        blob.metadata['scan_error'] = 'Malware détecté: EICAR-Test-File'
        blob.save!

        file_response.documents.attach(blob)

        # Reload association to ensure file_response is included
        market_application.market_attribute_responses.reload

        # Validation during upload should pass
        expect(file_response.valid?).to be true

        # Validation during intermediate form steps should also pass
        context = file_response.market_attribute.subcategory_key
        expect(market_application.valid?(context)).to be true

        # Validation at summary should fail if malware detected
        is_valid = market_application.valid?(:summary)
        expect(is_valid).to be false
        # Errors are propagated to the parent market_application
        expect(market_application.errors[:base]).to include(match(/Malware détecté/))
        expect(file_response.documents).to be_attached # File remains attached for display
      end

      it 'accepts files that passed security scan' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('dummy content'),
          filename: 'safe.pdf',
          content_type: 'application/pdf'
        )
        blob.metadata['scan_safe'] = true
        blob.metadata['scanned_at'] = Time.current.iso8601
        blob.save!

        file_response.documents.attach(blob)

        expect(file_response.valid?).to be true
        expect(file_response.errors[:documents]).to be_empty
      end
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

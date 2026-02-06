# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileOrTextarea, type: :model do
  let(:file_or_textarea_response) { create(:market_attribute_response_file_or_textarea) }

  describe 'included concerns' do
    it 'includes FileAttachable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::FileAttachable)
    end

    it 'includes JsonValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::JsonValidatable)
    end

    it 'includes TextValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::TextValidatable)
    end
  end

  describe 'JSON schema configuration' do
    it 'defines json_schema_properties with text' do
      expect(described_class.json_schema_properties).to eq(%i[text])
    end

    it 'defines json_schema_required as empty array' do
      expect(described_class.json_schema_required).to eq([])
    end

    it 'defines json_schema_error_field as :value' do
      expect(described_class.json_schema_error_field).to eq(:value)
    end
  end

  describe 'FileAttachable behavior' do
    it 'has documents attachment' do
      expect(file_or_textarea_response).to respond_to(:documents)
      expect(file_or_textarea_response.documents).to be_an(ActiveStorage::Attached::Many)
    end

    it 'responds to files=' do
      expect(file_or_textarea_response).to respond_to(:files=)
    end
  end

  describe 'TextValidatable behavior' do
    it 'responds to text accessor' do
      expect(file_or_textarea_response).to respond_to(:text)
      expect(file_or_textarea_response).to respond_to(:text=)
    end

    it 'stores text in value hash' do
      file_or_textarea_response.text = 'Test content'
      expect(file_or_textarea_response.value['text']).to eq('Test content')
    end
  end

  describe 'combined file and text usage' do
    it 'allows setting both text and files' do
      file_or_textarea_response.text = 'Justification text'
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('test content'),
        filename: 'justification.pdf',
        content_type: 'application/pdf'
      )
      file_or_textarea_response.documents.attach(blob)

      expect(file_or_textarea_response.text).to eq('Justification text')
      expect(file_or_textarea_response.documents.count).to eq(1)
    end

    it 'allows text without files' do
      file_or_textarea_response.text = 'Text only response'
      file_or_textarea_response.valid?
      expect(file_or_textarea_response.errors).to be_empty
    end

    it 'allows files without text' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('test content'),
        filename: 'document.pdf',
        content_type: 'application/pdf'
      )
      file_or_textarea_response.documents.attach(blob)
      file_or_textarea_response.valid?
      expect(file_or_textarea_response.errors).to be_empty
    end
  end
end

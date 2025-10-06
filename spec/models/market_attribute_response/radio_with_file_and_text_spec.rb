# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::RadioWithFileAndText, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :radio_with_file_and_text) }

  subject(:response) do
    described_class.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe 'associations' do
    let(:value) { {} }

    it { is_expected.to belong_to(:market_application) }
    it { is_expected.to belong_to(:market_attribute) }
  end

  describe 'includes' do
    let(:value) { {} }

    it 'includes RadioFieldBehavior concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::RadioFieldBehavior)
    end

    it 'includes TextFieldBehavior concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::TextFieldBehavior)
    end

    it 'includes FileAttachable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::FileAttachable)
    end

    it 'includes JsonValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::JsonValidatable)
    end
  end

  describe 'JSON schema validation' do
    context 'with empty value' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end

    context 'with empty hash' do
      let(:value) { {} }

      it { is_expected.to be_valid }
    end

    context 'with radio_choice only' do
      let(:value) { { 'radio_choice' => 'no' } }

      it { is_expected.to be_valid }
    end

    context 'with invalid additional properties' do
      let(:value) { { 'radio_choice' => 'yes', 'text' => 'Some text', 'invalid_key' => 'value' } }

      it { is_expected.to be_invalid }

      it 'adds validation error' do
        response.valid?
        expect(response.errors[:value]).to be_present
      end
    end
  end

  describe 'radio choice scenarios' do
    context 'when radio is "no" with no text and no files' do
      let(:value) { { 'radio_choice' => 'no' } }

      it { is_expected.to be_valid }

      it 'radio_no? returns true' do
        expect(response.radio_no?).to be true
      end
    end

    context 'when radio is "yes" with no text and no files (both optional)' do
      let(:value) { { 'radio_choice' => 'yes' } }

      it { is_expected.to be_valid }

      it 'radio_yes? returns true' do
        expect(response.radio_yes?).to be true
      end
    end

    context 'when radio is "yes" with text only' do
      let(:value) { { 'radio_choice' => 'yes', 'text' => 'My answer here' } }

      it { is_expected.to be_valid }

      it 'stores the text' do
        expect(response.text).to eq('My answer here')
      end
    end

    context 'when radio is "yes" with files only' do
      let(:value) { { 'radio_choice' => 'yes' } }
      let(:file_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('dummy pdf content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end

      before do
        response.documents.attach(file_blob)
      end

      it { is_expected.to be_valid }

      it 'has attached documents' do
        expect(response.documents).to be_attached
        expect(response.documents.count).to eq(1)
      end
    end

    context 'when radio is "yes" with both text and files' do
      let(:value) { { 'radio_choice' => 'yes', 'text' => 'Here is my explanation' } }
      let(:file_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('dummy pdf content'),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )
      end

      before do
        response.documents.attach(file_blob)
      end

      it { is_expected.to be_valid }

      it 'stores both text and files' do
        expect(response.text).to eq('Here is my explanation')
        expect(response.documents).to be_attached
        expect(response.documents.count).to eq(1)
      end
    end
  end

  describe 'file validation' do
    let(:value) { { 'radio_choice' => 'yes' } }

    it 'validates file content type' do
      invalid_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('executable content'),
        filename: 'virus.exe',
        content_type: 'application/x-msdownload'
      )
      response.documents.attach(invalid_blob)

      expect(response).to be_invalid
      expect(response.errors[:documents]).to be_present
    end

    it 'validates file size' do
      large_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('a' * 101.megabytes),
        filename: 'huge.pdf',
        content_type: 'application/pdf'
      )
      response.documents.attach(large_blob)

      expect(response).to be_invalid
      expect(response.errors[:documents]).to be_present
    end

    it 'accepts valid files' do
      valid_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('valid pdf content'),
        filename: 'valid.pdf',
        content_type: 'application/pdf'
      )
      response.documents.attach(valid_blob)

      expect(response).to be_valid
    end
  end

  describe 'text validation' do
    let(:value) { { 'radio_choice' => 'yes' } }

    it 'accepts valid text' do
      response.text = 'This is my answer'
      expect(response).to be_valid
    end

    it 'validates text length' do
      response.text = 'a' * 10_001
      expect(response).to be_invalid
      expect(response.errors[:text]).to be_present
    end

    it 'accepts empty text when not required' do
      response.text = ''
      expect(response).to be_valid
    end

    it 'accepts nil text when not required' do
      response.text = nil
      expect(response).to be_valid
    end
  end

  describe '.json_schema_properties' do
    it 'returns radio_choice and text' do
      expect(described_class.json_schema_properties).to eq(%w[radio_choice text])
    end
  end

  describe '.json_schema_required' do
    it 'returns empty array (nothing required)' do
      expect(described_class.json_schema_required).to eq([])
    end
  end

  describe '.json_schema_error_field' do
    it 'returns :value' do
      expect(described_class.json_schema_error_field).to eq(:value)
    end
  end

  describe 'default behavior' do
    let(:value) { nil }

    it 'has default radio_choice of "no"' do
      expect(response.radio_choice).to eq('no')
    end

    it 'has nil text by default' do
      expect(response.text).to be_nil
    end

    it 'has no documents attached by default' do
      expect(response.documents).not_to be_attached
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::RadioWithJustificationRequired, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :radio_with_justification_required) }

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
    context 'with empty value (new record defaults to "no", needs documents)' do
      let(:value) { nil }

      it { is_expected.to be_invalid }

      it 'requires documents when defaulting to no' do
        response.valid?
        expect(response.errors[:documents]).to be_present
      end
    end

    context 'with empty hash (defaults to "no", needs documents)' do
      let(:value) { {} }

      it { is_expected.to be_invalid }

      it 'requires documents when defaulting to no' do
        response.valid?
        expect(response.errors[:documents]).to be_present
      end
    end

    context 'with radio_choice only' do
      let(:value) { { 'radio_choice' => 'yes' } }

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
    context 'when radio is "no" with no documents (INVALID - documents required)' do
      let(:value) { { 'radio_choice' => 'no' } }

      it { is_expected.to be_invalid }

      it 'requires documents' do
        response.valid?
        expect(response.errors[:documents]).to be_present
      end

      it 'radio_no? returns true' do
        expect(response.radio_no?).to be true
      end
    end

    context 'when radio is "no" with documents (VALID)' do
      let(:value) { { 'radio_choice' => 'no' } }
      let(:file_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('justification document'),
          filename: 'justification.pdf',
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

    context 'when radio is "no" with text (INVALID - text not allowed when no)' do
      let(:value) { { 'radio_choice' => 'no', 'text' => 'Some text' } }
      let(:file_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('justification document'),
          filename: 'justification.pdf',
          content_type: 'application/pdf'
        )
      end

      before do
        response.documents.attach(file_blob)
      end

      it { is_expected.to be_invalid }

      it 'does not allow text when no' do
        response.valid?
        expect(response.errors[:value]).to be_present
      end
    end

    context 'when radio is "yes" with no text and no files (VALID - both optional)' do
      let(:value) { { 'radio_choice' => 'yes' } }

      it { is_expected.to be_valid }

      it 'radio_yes? returns true' do
        expect(response.radio_yes?).to be true
      end
    end

    context 'when radio is "yes" with text only (VALID)' do
      let(:value) { { 'radio_choice' => 'yes', 'text' => 'We are compliant' } }

      it { is_expected.to be_valid }

      it 'stores the text' do
        expect(response.text).to eq('We are compliant')
      end
    end

    context 'when radio is "yes" with files only (VALID)' do
      let(:value) { { 'radio_choice' => 'yes' } }
      let(:file_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('supporting document'),
          filename: 'support.pdf',
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

    context 'when radio is "yes" with both text and files (VALID)' do
      let(:value) { { 'radio_choice' => 'yes', 'text' => 'Additional details' } }
      let(:file_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('supporting document'),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )
      end

      before do
        response.documents.attach(file_blob)
      end

      it { is_expected.to be_valid }

      it 'stores both text and files' do
        expect(response.text).to eq('Additional details')
        expect(response.documents).to be_attached
        expect(response.documents.count).to eq(1)
      end
    end
  end

  describe 'file validation' do
    let(:value) { { 'radio_choice' => 'no' } }

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
      response.text = 'This is my explanation'
      expect(response).to be_valid
    end

    it 'validates text length' do
      response.text = 'a' * 10_001
      expect(response).to be_invalid
      expect(response.errors[:text]).to be_present
    end

    it 'accepts empty text when yes selected' do
      response.text = ''
      expect(response).to be_valid
    end

    it 'accepts nil text when yes selected' do
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
    it 'returns empty array (nothing required in JSON)' do
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

  describe 'yes to no transition (data clearing)' do
    let(:value) { {} }
    let(:file_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('test content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
    end

    context 'when switching from yes with text to no' do
      it 'clears the text field' do
        response.radio_choice = 'yes'
        response.text = 'Compliant information'
        expect(response.text).to eq('Compliant information')

        response.radio_choice = 'no'
        expect(response.text).to be_nil
        expect(response.value).to eq({ 'radio_choice' => 'no' })
      end
    end

    context 'when switching from yes with files to no' do
      it 'purges attached documents' do
        response.radio_choice = 'yes'
        response.documents.attach(file_blob)
        expect(response.documents).to be_attached

        response.radio_choice = 'no'
        expect(response.documents).not_to be_attached
      end
    end

    context 'when switching from yes with both text and files to no' do
      it 'clears text and purges files' do
        response.radio_choice = 'yes'
        response.text = 'See attached document'
        response.documents.attach(file_blob)

        expect(response.text).to be_present
        expect(response.documents).to be_attached

        response.radio_choice = 'no'

        expect(response.text).to be_nil
        expect(response.documents).not_to be_attached
        expect(response.value).to eq({ 'radio_choice' => 'no' })
      end
    end
  end

  describe 'data consistency validation' do
    let(:value) { {} }

    context 'when radio is no without documents (inconsistent state)' do
      it 'is invalid' do
        response.value = { 'radio_choice' => 'no' }

        expect(response).to be_invalid
        expect(response.errors[:documents]).to be_present
      end
    end

    context 'when radio is no with text in value (inconsistent state)' do
      it 'is invalid' do
        response.value = { 'radio_choice' => 'no', 'text' => 'leftover data' }
        response.documents.attach(
          ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new('test'),
            filename: 'test.pdf',
            content_type: 'application/pdf'
          )
        )

        expect(response).to be_invalid
        expect(response.errors[:value]).to be_present
      end
    end

    context 'when radio is yes with text and documents' do
      it 'is valid' do
        response.radio_choice = 'yes'
        response.text = 'Valid explanation'
        response.documents.attach(
          ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new('test'),
            filename: 'test.pdf',
            content_type: 'application/pdf'
          )
        )

        expect(response).to be_valid
      end
    end
  end
end

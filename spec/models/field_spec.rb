# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Field, type: :model do
  subject(:field) do
    Field.new(
      key: 'unicorn_birth_certificate',
      type: 'document_upload',
      category: 'unicorn_identity',
      subcategory: 'basic_documents',
      source_type: 'authentic_source',
      required_for: %w[supplies works],
      optional_for: [],
      defense_required: false,
      defense_optional: false
    )
  end

  describe 'validations' do
    it 'validates presence of required attributes' do
      expect(field).to be_valid

      field.key = nil
      expect(field).not_to be_valid
      expect(field.errors[:key]).to be_present
    end

    it 'validates field type inclusion' do
      field.type = 'invalid_type'
      expect(field).not_to be_valid
      expect(field.errors[:type]).to be_present
    end

    it 'validates source type inclusion' do
      field.source_type = 'invalid_source'
      expect(field).not_to be_valid
      expect(field.errors[:source_type]).to be_present
    end
  end

  describe '#required_for_market_type?' do
    it 'returns true when market type is in required_for array' do
      expect(field.required_for_market_type?('supplies')).to be true
      expect(field.required_for_market_type?(:supplies)).to be true
    end

    it 'returns false when market type is not in required_for array' do
      expect(field.required_for_market_type?('services')).to be false
    end
  end

  describe '#optional_for_market_type?' do
    it 'returns true when market type is in optional_for array' do
      field.optional_for = ['services']
      expect(field.optional_for_market_type?('services')).to be true
    end

    it 'returns false when market type is not in optional_for array' do
      expect(field.optional_for_market_type?('services')).to be false
    end
  end

  describe 'localization methods' do
    it 'returns localized name' do
      expect(field.localized_name).to eq(I18n.t('form_fields.fields.unicorn_birth_certificate.name'))
    end

    it 'returns localized description' do
      expect(field.localized_description).to eq(I18n.t('form_fields.fields.unicorn_birth_certificate.description'))
    end

    it 'returns source info' do
      expected_source_info = I18n.t('form_fields.source_types.authentic_source')
      expect(field.source_info).to eq(expected_source_info)
    end
  end

  describe 'type predicates' do
    it 'identifies document upload fields' do
      expect(field).to be_document_upload
      expect(field).not_to be_text_field
      expect(field).not_to be_checkbox_field
    end

    it 'identifies text fields' do
      field.type = 'text_field'
      expect(field).to be_text_field
      expect(field).not_to be_document_upload
      expect(field).not_to be_checkbox_field
    end

    it 'identifies checkbox fields' do
      field.type = 'checkbox_field'
      expect(field).to be_checkbox_field
      expect(field).not_to be_document_upload
      expect(field).not_to be_text_field
    end
  end

  describe 'source predicates' do
    it 'identifies authentic source fields' do
      expect(field).to be_authentic_source
      expect(field).not_to be_honor_declaration
    end

    it 'identifies honor declaration fields' do
      field.source_type = 'honor_declaration'
      expect(field).to be_honor_declaration
      expect(field).not_to be_authentic_source
    end
  end
end

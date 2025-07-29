# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Field, type: :model do
  subject(:field) do
    Field.new(
      key: 'unicorn_birth_certificate',
      type: 'document_upload',
      category: 'unicorn_identity',
      subcategory: 'basic_documents',
      source_type: 'authentic_source'
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

  describe 'localization via Rails I18n' do
    it 'supports localized field names via human_attribute_name' do
      expect(Field.human_attribute_name("fields.#{field.key}.name")).to be_a(String)
    end

    it 'supports localized descriptions via human_attribute_name' do
      expect(Field.human_attribute_name("fields.#{field.key}.description")).to be_a(String)
    end

    it 'supports source type info via I18n' do
      source_info = I18n.t("activemodel.attributes.field.source_types.#{field.source_type}")
      expect(source_info).to be_a(Hash)
      expect(source_info).to have_key(:label)
      expect(source_info).to have_key(:badge_class)
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

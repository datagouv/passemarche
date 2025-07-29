# frozen_string_literal: true

class Field
  include FieldConstants
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :key, :string
  attribute :type, :string
  attribute :category, :string
  attribute :subcategory, :string
  attribute :source_type, :string

  validates :key, :type, :category, :subcategory, :source_type, presence: true
  validates :type, inclusion: { in: FIELD_TYPES }
  validates :source_type, inclusion: { in: SOURCE_TYPES }


  def document_upload?
    type == 'document_upload'
  end

  def text_field?
    type == 'text_field'
  end

  def checkbox_field?
    type == 'checkbox_field'
  end

  def authentic_source?
    source_type == 'authentic_source'
  end

  def honor_declaration?
    source_type == 'honor_declaration'
  end
end

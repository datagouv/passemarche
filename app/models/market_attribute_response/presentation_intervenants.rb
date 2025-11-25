# frozen_string_literal: true

class MarketAttributeResponse::PresentationIntervenants < MarketAttributeResponse
  include MarketAttributeResponse::RepeatableField

  PERSON_FIELDS = %w[nom prenoms titres cv_attachment_id].freeze

  def self.item_schema
    {
      'nom' => { type: 'string', required: true },
      'prenoms' => { type: 'string', required: true },
      'titres' => { type: 'text', required: false },
      'cv_attachment_id' => { type: 'file', required: false }
    }
  end

  def self.json_schema_properties
    %w[items]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end

  alias persons items
  alias persons= items=
  alias persons_ordered items_ordered

  validate :validate_persons_structure

  def specialized_document_fields
    ['cv_attachment_id']
  end

  def person_cv_attachment(person_timestamp)
    get_specialized_documents(person_timestamp, 'cv_attachment_id')
  end

  def item_prefix
    'person'
  end

  def item_data_fields
    PERSON_FIELDS
  end

  private

  def validate_persons_structure
    return if value.blank?

    unless value.is_a?(Hash)
      errors.add(:value, 'must be a hash')
      return
    end

    persons_data = value['items']
    return if persons_data.blank?

    unless persons_data.is_a?(Hash)
      errors.add(:value, 'persons must be a hash')
      return
    end

    persons_data.each_with_index do |(_timestamp, person), display_index|
      validate_single_person(person, display_index + 1)
    end
  end

  def validate_single_person(person, display_number)
    return if person.is_a?(Hash)

    errors.add(:value, "Person #{display_number} must be a hash")
  end

  def person_has_data?(person)
    return false unless person.is_a?(Hash)

    PERSON_FIELDS.any? { |field| person[field].present? }
  end
end

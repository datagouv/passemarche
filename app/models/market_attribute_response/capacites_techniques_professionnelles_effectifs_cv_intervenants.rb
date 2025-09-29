# frozen_string_literal: true

class MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants < MarketAttributeResponse
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable

  # Expected JSON structure:
  # {
  #   "persons": [
  #     {
  #       "nom": "Dupont",
  #       "prenoms": "Jean",
  #       "titres": "Ingénieur",
  #       "cv_attachment_id": "123"
  #     }
  #   ]
  # }

  def self.json_schema_properties
    %w[persons]
  end

  def self.json_schema_required
    [] # Allow empty data initially
  end

  def self.json_schema_error_field
    :value
  end

  validate :validate_persons_structure

  # Virtual attribute for persons array
  def persons
    value&.dig('persons') || []
  end

  def persons=(persons_array)
    self.value = {} if value.blank?
    value['persons'] = persons_array.is_a?(Array) ? persons_array : []
  end

  private

  def validate_persons_structure
    return if value.blank?

    unless value.is_a?(Hash)
      errors.add(:value, 'must be a hash')
      return
    end

    persons_data = value['persons']
    return if persons_data.blank?

    unless persons_data.is_a?(Array)
      errors.add(:value, 'persons must be an array')
      return
    end

    persons_data.each_with_index do |person, index|
      validate_single_person(person, index)
    end
  end

  def validate_single_person(person, index)
    unless person.is_a?(Hash)
      errors.add(:value, "Person at index #{index} must be a hash")
      return
    end

    # For now, just validate that if person data exists, it has some content
    return unless person_has_data?(person)

    # Basic validation - at least nom should be present if any field is filled
    return if person['nom'].present?

    errors.add(:value, "Person at index #{index}: nom is required when person data is provided")
  end

  def person_has_data?(person)
    return false unless person.is_a?(Hash)

    %w[nom prenoms titres cv_attachment_id].any? { |field| person[field].present? }
  end
end

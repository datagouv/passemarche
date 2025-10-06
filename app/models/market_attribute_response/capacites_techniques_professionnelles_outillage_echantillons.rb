# frozen_string_literal: true

class MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons < MarketAttributeResponse
  include MarketAttributeResponse::RepeatableField

  ECHANTILLON_FIELDS = %w[description fichiers].freeze

  def self.item_schema
    {
      'description' => { type: 'text', required: true },
      'fichiers' => { type: 'file', required: false }
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

  def item_prefix
    'echantillon'
  end

  def specialized_document_fields
    ['fichiers']
  end

  def cleanup_old_specialized_documents?
    false
  end

  alias echantillons items
  alias echantillons= items=
  alias echantillons_ordered items_ordered

  validate :validate_echantillons_structure

  def echantillon_fichiers(echantillon_timestamp)
    return [] unless documents.attached?

    documents.select do |doc|
      doc.metadata['field_type'] == 'specialized' &&
        doc.metadata['item_timestamp'] == echantillon_timestamp.to_s &&
        doc.metadata['field_name'] == 'fichiers'
    end
  end

  private

  def validate_echantillons_structure
    return if value.blank?

    unless value.is_a?(Hash)
      errors.add(:value, 'must be a hash')
      return
    end

    echantillons_data = value['items']
    return if echantillons_data.blank?

    unless echantillons_data.is_a?(Hash)
      errors.add(:value, 'echantillons must be a hash')
      return
    end

    echantillons_data.each_with_index do |(timestamp, echantillon), display_index|
      validate_single_echantillon(timestamp, echantillon, display_index + 1)
    end
  end

  def validate_single_echantillon(_timestamp, echantillon, display_number)
    unless echantillon.is_a?(Hash)
      errors.add(:value, "Échantillon #{display_number} must be a hash")
      return
    end

    return unless echantillon_has_data?(echantillon)
    return unless market_attribute&.required?

    return if echantillon['description'].present?

    errors.add(:value, "Échantillon #{display_number}: description is required when echantillon data is provided")
  end

  def echantillon_has_data?(echantillon)
    return false unless echantillon.is_a?(Hash)

    ECHANTILLON_FIELDS.any? { |field| echantillon[field].present? }
  end
end

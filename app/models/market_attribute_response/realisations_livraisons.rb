# frozen_string_literal: true

class MarketAttributeResponse::RealisationsLivraisons < MarketAttributeResponse
  include MarketAttributeResponse::RepeatableField

  REALISATION_FIELDS = %w[
    resume
    date_debut
    date_fin
    montant
    description
    attestation_bonne_execution
  ].freeze

  def self.item_schema
    {
      'resume' => { type: 'string', required: true },
      'date_debut' => { type: 'date', required: true },
      'date_fin' => { type: 'date', required: true },
      'montant' => { type: 'integer', required: true },
      'description' => { type: 'text', required: true },
      'attestation_bonne_execution' => { type: 'file', required: false }
    }
  end

  def item_prefix
    'realisation'
  end

  def item_data_fields
    REALISATION_FIELDS
  end

  def specialized_document_fields
    ['attestation_bonne_execution']
  end

  alias realisations items
  alias realisations= items=
  alias realisations_ordered items_ordered

  validate :validate_realisations_structure

  def realisation_attestations(realisation_timestamp)
    get_specialized_documents(realisation_timestamp, 'attestation_bonne_execution')
  end

  def set_item_field(item_timestamp, field_name, field_value)
    coerced_value = coerce_field_value(field_name, field_value)
    super(item_timestamp, field_name, coerced_value)
  end

  private

  def coerce_field_value(field_name, val)
    if field_name == 'montant'
      val.presence&.to_i
    else
      val.presence
    end
  end

  def validate_realisations_structure
    return if value.blank?

    unless value.is_a?(Hash)
      errors.add(:value, 'must be a hash')
      return
    end

    realisations_data = value['items']
    return if realisations_data.blank?

    unless realisations_data.is_a?(Hash)
      errors.add(:value, 'realisations must be a hash')
      return
    end

    realisations_data.each_with_index do |(timestamp, realisation), display_index|
      validate_single_realisation(timestamp, realisation, display_index + 1)
    end
  end

  def validate_single_realisation(timestamp, realisation, display_number)
    unless realisation.is_a?(Hash)
      errors.add(:value, "Réalisation #{display_number} must be a hash")
      return
    end

    return unless realisation_has_data?(realisation)

    validate_realisation_dates(realisation, display_number, timestamp)
    validate_realisation_montant(realisation, display_number)
  end

  def realisation_has_data?(realisation)
    return false unless realisation.is_a?(Hash)

    REALISATION_FIELDS.any? { |field| realisation[field].present? }
  end

  def validate_realisation_dates(realisation, display_number, _timestamp)
    date_debut = parse_realisation_date(realisation['date_debut'], display_number, 'date_debut')
    date_fin = parse_realisation_date(realisation['date_fin'], display_number, 'date_fin')

    return unless date_debut && date_fin

    return if date_fin >= date_debut

    errors.add(:value, "Réalisation #{display_number}: date_fin must be after or equal to date_debut")
  end

  def parse_realisation_date(date_string, display_number, field_name)
    return nil if date_string.blank?

    Date.iso8601(date_string.to_s)
  rescue ArgumentError
    errors.add(:value, "Réalisation #{display_number}: #{field_name} must be in YYYY-MM-DD format")
    nil
  end

  def validate_realisation_montant(realisation, display_number)
    montant = realisation['montant']
    return if montant.blank?

    return if montant.is_a?(Integer) && montant.positive?

    errors.add(:value, "Réalisation #{display_number}: montant must be a positive integer")
  end
end

# frozen_string_literal: true

class MarketAttributeResponse::CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns < MarketAttributeResponse
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
    'realisation'
  end

  def specialized_document_fields
    ['attestation_bonne_execution']
  end

  def cleanup_old_specialized_documents?
    false
  end

  alias realisations items
  alias realisations= items=
  alias realisations_ordered items_ordered

  def realisation_attestations(realisation_timestamp)
    get_specialized_document(realisation_timestamp, 'attestation_bonne_execution')
  end
end

# frozen_string_literal: true

# Example of expected structure for the "jugement" field in a record from BODACC API v2.1:
# jugement: {
#   "type": "initial",
#   "famille": "Extrait de jugement",
#   "nature": "Jugement prononçant la résolution du plan de redressement et la liquidation judiciaire",
#   "date": "2022-03-09",
#   "complementJugement": "Jugement prononçant la résolution du plan de redressement et la liquidation judiciaire..."
# }
#

class Bodacc::BuildResource < ApplicationInteractor
  # Keywords for detecting a risky manager in the judgment nature or complement
  # "faillite personnelle", "interdiction de gérer", "banqueroute"
  DIRIGEANT_RISK_KEYWORDS = /faillite personnelle|interdiction de gérer|banqueroute/i

  def call
    analyze_records
    build_bundled_data
  end

  protected

  def analyze_records
    if context.records.blank?
      context.liquidation_detected = false
      context.dirigeant_a_risque = false
    else
      analyze_legal_situations
    end
  end

  def build_bundled_data
    resource = Resource.new(resource_attributes)
    context.bundled_data = BundledData.new(
      data: resource,
      context: {
        liquidation_detected: context.liquidation_detected,
        dirigeant_a_risque: context.dirigeant_a_risque
      }
    )
  end

  private

  def analyze_legal_situations
    context.liquidation_detected = context.records.any? { |record| liquidation_judiciaire?(normalize_record(record)) }
    context.dirigeant_a_risque = context.records.any? { |record| dirigeant_a_risque?(normalize_record(record)) }
  end

  def normalize_record(record)
    record.is_a?(Hash) && record.key?('fields') ? record['fields'] : record
  end

  def resource_attributes
    {
      liquidation_judiciaire: build_radio_with_file_and_text(
        context.liquidation_detected,
        'Procédure de liquidation judiciaire détectée'
      ),
      faillite_interdiction: build_radio_with_file_and_text(
        context.dirigeant_a_risque,
        'Dirigeant à risque détecté'
      )
    }
  end

  def build_radio_with_file_and_text(detected, text)
    if detected
      {
        'radio_choice' => 'yes',
        'text' => text,
        'hidden' => true # field is hidden in the form when auto-detected
      }
    else
      { 'radio_choice' => 'no' }
    end
  end

  def liquidation_judiciaire?(record)
    return false unless actes_et_procedures_collectives?(record)

    jugement = jugement_hash(record['jugement'])
    return false if jugement.blank?

    # Parse text from nature and complementJugement fields
    nature = normalized_text(jugement['nature'])
    complement = normalized_text(jugement['complementJugement'])

    nature.match?(/liquidation/i) || complement.match?(/liquidation judiciaire/i)
  end

  def dirigeant_a_risque?(record)
    return false unless actes_et_procedures_collectives?(record)

    jugement = jugement_hash(record['jugement'])
    return false if jugement.blank?

    # Parse text from nature and complementJugement fields
    nature = normalized_text(jugement['nature'])
    complement = normalized_text(jugement['complementJugement'])

    nature.match?(DIRIGEANT_RISK_KEYWORDS) || complement.match?(DIRIGEANT_RISK_KEYWORDS)
  end

  def actes_et_procedures_collectives?(record)
    # 'A' = Actes et procédures collectives
    record['publicationavis'] == 'A'
  end

  def jugement_hash(jugement_field)
    return jugement_field if jugement_field.is_a?(Hash)

    safe_json_parse(jugement_field)
  end

  def normalized_text(text)
    text.to_s.strip.downcase
  end

  def safe_json_parse(value)
    return {} if value.blank?

    JSON.parse(value)
  rescue JSON::ParserError, TypeError => e
    Rails.logger.debug { "[Bodacc::BuildResource] Failed to parse JSON: #{e.message}" }
    {}
  end
end

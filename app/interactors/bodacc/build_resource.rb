# frozen_string_literal: true

# Example of expected structure for the "jugement" field in a record:
# {
#   "date": "2024-09-12",
#   "tribunal": "Tribunal de commerce de Paris",
#   "nature": "Liquidation judiciaire",
#   "codeNature": "LJ",
#   "dateCessationPaiements": "2024-08-01"
# }

class Bodacc::BuildResource < ApplicationInteractor
  # Codes nature pour liquidation judiciaire
  # lj  = Liquidation judiciaire
  # ljs = Liquidation judiciaire simplifiée
  # ljp = Liquidation judiciaire particulière / prononcée
  LIQUIDATION_CODES = %w[lj ljs ljp].freeze

  # Codes nature pour dirigeant à risque
  # fp = Faillite personnelle
  # ig = Interdiction de gérer
  # bq = Banqueroute
  DIRIGEANT_RISK_CODES = %w[fp ig bq].freeze

  # Keywords detecting a risky manager in the judgment nature
  # "faillite personnelle", "interdiction de gérer", "banqueroute"
  DIRIGEANT_RISK_KEYWORDS = /faillite personnelle|interdiction de gérer|banqueroute/i

  private_constant :LIQUIDATION_CODES, :DIRIGEANT_RISK_CODES

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
        'Procédure de liquidation judicière'
      ),
      faillite_interdiction: build_radio_with_file_and_text(
        context.dirigeant_a_risque,
        'Dirigeant à risque détecté par Bodacc'
      )
    }
  end

  def build_radio_with_file_and_text(detected, text)
    detected ? { 'radio_choice' => 'yes', 'text' => text } : { 'radio_choice' => 'no' }
  end

  def liquidation_judiciaire?(record)
    return false unless actes_et_procedures_collectives?(record)

    jugement = jugement_hash(record['jugement'])
    return false if jugement.blank?

    code = normalized_code(jugement['codeNature'])
    nature = normalized_nature(jugement['nature'])

    LIQUIDATION_CODES.include?(code) || nature.match?(/liquidation/i)
  end

  def dirigeant_a_risque?(record)
    return false unless actes_et_procedures_collectives?(record)

    jugement = jugement_hash(record['jugement'])
    return false if jugement.blank?

    code = normalized_code(jugement['codeNature'])
    nature = normalized_nature(jugement['nature'])

    DIRIGEANT_RISK_CODES.include?(code) || nature.match?(DIRIGEANT_RISK_KEYWORDS)
  end

  def actes_et_procedures_collectives?(record)
    # 'A' = Actes et procédures collectives
    record['publicationavis'] == 'A'
  end

  def jugement_hash(jugement_field)
    return jugement_field if jugement_field.is_a?(Hash)

    safe_json_parse(jugement_field)
  end

  def normalized_code(code)
    code.to_s.strip.downcase
  end

  def normalized_nature(nature)
    nature.to_s.strip.downcase
  end

  def safe_json_parse(value)
    return {} if value.blank?

    JSON.parse(value)
  rescue StandardError
    {}
  end
end

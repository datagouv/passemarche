# frozen_string_literal: true

# Component for displaying annual average workforce (effectifs moyens annuels) data
# Maps to input_type: :capacite_economique_financiere_effectifs_moyens_annuels
class MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent < MarketAttributeResponse::BaseComponent
  YEAR_KEYS = %w[year_1 year_2 year_3].freeze
  YEAR_LABELS = { 'year_1' => 'n-1', 'year_2' => 'n-2', 'year_3' => 'n-3' }.freeze

  delegate :value, to: :market_attribute_response

  def value_data
    value || {}
  end

  def data?
    value_data.present? && value_data.any? { |_, year_data| year_data.is_a?(Hash) && year_data.values.any?(&:present?) }
  end

  def year_data(year_key)
    value_data[year_key] || {}
  end

  def year_value(year_key)
    year_data(year_key)['year']
  end

  def average_staff_value(year_key)
    year_data(year_key)['average_staff']
  end

  def year_label(year_key)
    YEAR_LABELS[year_key] || year_key
  end

  def not_provided_message
    'Non renseigné'
  end

  def errors?
    market_attribute_response.errors[:value].any? ||
      YEAR_KEYS.any? { |year_key| market_attribute_response.errors[year_key.to_sym].any? }
  end

  def value_error_messages
    market_attribute_response.errors[:value]
  end

  def year_error_messages(year_key)
    market_attribute_response.errors[year_key.to_sym]
  end

  def current_year
    Time.current.year
  end
end

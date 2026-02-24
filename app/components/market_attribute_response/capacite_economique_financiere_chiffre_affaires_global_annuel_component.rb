# frozen_string_literal: true

# Component for displaying annual turnover (chiffre d'affaires) data
# Maps to input_type: :capacite_economique_financiere_chiffre_affaires_global_annuel
class MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuelComponent < MarketAttributeResponse::BaseComponent
  YEAR_KEYS = %w[year_1 year_2 year_3].freeze
  FIELD_NAMES = %w[turnover market_percentage fiscal_year_end].freeze

  delegate :value, to: :market_attribute_response

  def value_data
    value || {}
  end

  def data?
    value_data.present? && value_data.any? { |_, year_data| year_data.is_a?(Hash) && year_data.values.any?(&:present?) }
  end

  def api_data?
    return false unless auto?

    api_fields = value_data['_api_fields']
    return false if api_fields.blank?

    YEAR_KEYS.any? { |year_key| api_fields[year_key]&.any? }
  end

  def year_data(year_key)
    value_data[year_key] || {}
  end

  def api_fields_for_year(year_key)
    api_fields = value_data['_api_fields'] || {}
    api_fields[year_key] || []
  end

  def field_from_api?(year_key, field_name)
    auto? && api_fields_for_year(year_key).include?(field_name)
  end

  def turnover_value(year_key)
    year_data(year_key)['turnover']
  end

  def formatted_turnover(year_key)
    turnover = turnover_value(year_key)
    return nil if turnover.blank?

    "#{ActiveSupport::NumberHelper.number_to_delimited(turnover, delimiter: ' ')} €"
  end

  def market_percentage_value(year_key)
    year_data(year_key)['market_percentage']
  end

  def formatted_market_percentage(year_key)
    percentage = market_percentage_value(year_key)
    return nil if percentage.blank?

    "#{percentage} %"
  end

  def fiscal_year_end_value(year_key)
    year_data(year_key)['fiscal_year_end']
  end

  def formatted_fiscal_year_end(year_key)
    date_str = fiscal_year_end_value(year_key)
    return nil if date_str.blank?

    Date.parse(date_str).strftime('%d/%m/%Y')
  rescue ArgumentError
    date_str
  end

  def year_label(year_key, index)
    I18n.t(
      "candidate.market_applications.form_fields.capacite_economique_financiere_chiffre_affaires_global_annuel.year_labels.#{year_key}",
      default: "Année #{index + 1}"
    )
  end

  def table_header(key)
    I18n.t("candidate.market_applications.form_fields.capacite_economique_financiere_chiffre_affaires_global_annuel.table_headers.#{key}")
  end

  def notice_message
    I18n.t('candidate.market_applications.form_fields.capacite_economique_financiere_chiffre_affaires_global_annuel.notice')
  end

  def display_turnover(year_key)
    if field_from_api?(year_key, 'turnover')
      { value: (formatted_turnover(year_key) if context == :buyer), source: :auto }
    elsif turnover_value(year_key).present?
      { value: formatted_turnover(year_key), source: :manual_after_api_failure }
    end
  end

  def display_fiscal_year_end(year_key)
    if field_from_api?(year_key, 'fiscal_year_end')
      { value: formatted_fiscal_year_end(year_key), source: :auto }
    elsif fiscal_year_end_value(year_key).present?
      { value: formatted_fiscal_year_end(year_key), source: :manual_after_api_failure }
    end
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

  def table_class
    context == :web ? 'fr-table' : 'ca-table'
  end

  def table_style
    context == :web ? 'border:1px solid #ddd;width:100%;' : ''
  end
end

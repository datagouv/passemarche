# frozen_string_literal: true

module MarketAttributeResponse::YearlyDataValidatable
  extend ActiveSupport::Concern

  private

  def year_has_any_data?(year_data)
    year_data.is_a?(Hash) && year_data.values.any?(&:present?)
  end

  def valid_positive_integer?(value)
    value.is_a?(Integer) && !value.negative?
  end
end

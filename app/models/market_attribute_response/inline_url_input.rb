# frozen_string_literal: true

class MarketAttributeResponse::InlineUrlInput < MarketAttributeResponse::UrlInput
  def date_delivrance_certificat
    value&.[]('date_delivrance_certificat')
  end

  def duree_validite_certificat
    value&.[]('duree_validite_certificat')
  end

  def formatted_date_delivrance
    return nil if date_delivrance_certificat.blank?

    Date.parse(date_delivrance_certificat)
  rescue ArgumentError, TypeError
    nil
  end

  def opqibi_metadata?
    market_attribute&.api_name == 'opqibi' &&
      (date_delivrance_certificat.present? || duree_validite_certificat.present?)
  end
end

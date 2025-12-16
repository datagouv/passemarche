# frozen_string_literal: true

class MarketAttributeResponse::ApiDisplay::OpqibiComponent < MarketAttributeResponse::ApiDisplay::BaseComponent
  delegate :date_delivrance_certificat,
    :duree_validite_certificat,
    :formatted_date_delivrance,
    :text,
    to: :market_attribute_response

  def date_delivrance?
    formatted_date_delivrance.present?
  end

  def duree_validite?
    duree_validite_certificat.present?
  end

  def url?
    text.present?
  end

  def formatted_date_delivrance_long
    return nil unless date_delivrance?

    I18n.l(formatted_date_delivrance, format: :long)
  end
end

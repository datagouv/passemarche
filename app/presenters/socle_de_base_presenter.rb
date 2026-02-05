# frozen_string_literal: true

class SocleDeBasePresenter
  def initialize(market_attribute)
    @market_attribute = market_attribute
  end

  def buyer_name
    I18n.t("form_fields.buyer.fields.#{key}.name", default: key.humanize)
  end

  def candidate_name
    I18n.t("form_fields.candidate.fields.#{key}.name", default: key.humanize)
  end

  private

  def key
    @market_attribute.key
  end
end

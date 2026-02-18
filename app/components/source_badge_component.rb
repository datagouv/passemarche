# frozen_string_literal: true

class SourceBadgeComponent < ViewComponent::Base
  attr_reader :market_attribute_response

  def initialize(market_attribute_response: nil, source: nil, context: :candidate)
    @market_attribute_response = market_attribute_response
    @explicit_source = source
    @context = context
  end

  def render?
    effective_source.present?
  end

  def badge_text
    scope = badge_i18n_scope
    case effective_source
    when :auto
      I18n.t("#{scope}.data_from_api")
    when :manual_after_api_failure
      I18n.t("#{scope}.declared_on_honor")
    end
  end

  def badge_css_class
    case effective_source
    when :auto
      'fr-badge fr-badge--success fr-badge--sm'
    when :manual_after_api_failure
      'fr-badge fr-badge--info fr-badge--sm'
    end
  end

  private

  def badge_i18n_scope
    if @context == :buyer
      'buyer.attestations.badges'
    else
      'candidate.market_applications.badges'
    end
  end

  def effective_source
    @explicit_source || infer_source_from_response
  end

  def infer_source_from_response
    return nil unless @market_attribute_response

    return :auto if @market_attribute_response.auto?
    return :manual_after_api_failure if @market_attribute_response.manual_after_api_failure?

    nil
  end
end

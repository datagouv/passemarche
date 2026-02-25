# frozen_string_literal: true

class SourceBadgeComponent < ViewComponent::Base
  def initialize(market_attribute_response: nil, source: nil, context: nil)
    @market_attribute_response = market_attribute_response
    @explicit_source = source
    @context = context
  end

  def render?
    return false if effective_source.blank?
    return true if auto?

    manual? && @context == :buyer
  end

  def badge_text
    return I18n.t('shared.source_badge.data_from_api') if auto?

    I18n.t('shared.source_badge.declared_by_candidate') if manual?
  end

  def badge_css_class
    return 'fr-badge fr-badge--success fr-badge--sm' if auto?

    'fr-badge fr-badge--info fr-badge--sm' if manual?
  end

  private

  def auto?
    effective_source == :auto
  end

  def manual?
    %i[manual manual_after_api_failure].include?(effective_source)
  end

  def effective_source
    @explicit_source || infer_source_from_response
  end

  def infer_source_from_response
    return unless @market_attribute_response
    return :auto if @market_attribute_response.auto?

    :manual if @market_attribute_response.manual? || @market_attribute_response.manual_after_api_failure?
  end
end

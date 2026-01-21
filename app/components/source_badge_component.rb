# frozen_string_literal: true

class SourceBadgeComponent < ViewComponent::Base
  attr_reader :market_attribute_response

  def initialize(market_attribute_response: nil, source: nil)
    @market_attribute_response = market_attribute_response
    @explicit_source = source
  end

  def render?
    effective_source.present?
  end

  def badge_text
    case effective_source
    when :auto
      I18n.t('candidate.market_applications.badges.data_from_api')
    when :manual_after_api_failure
      I18n.t('candidate.market_applications.badges.declared_on_honor')
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

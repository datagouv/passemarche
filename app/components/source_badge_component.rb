# frozen_string_literal: true

class SourceBadgeComponent < ViewComponent::Base
  attr_reader :market_attribute_response

  def initialize(market_attribute_response:)
    @market_attribute_response = market_attribute_response
  end

  def render?
    market_attribute_response.auto? || market_attribute_response.manual_after_api_failure?
  end

  def badge_text
    if market_attribute_response.auto?
      I18n.t('candidate.market_applications.badges.data_from_api')
    elsif market_attribute_response.manual_after_api_failure?
      I18n.t('candidate.market_applications.badges.declared_on_honor')
    end
  end

  def badge_css_class
    if market_attribute_response.auto?
      'fr-badge fr-badge--success fr-badge--sm'
    elsif market_attribute_response.manual_after_api_failure?
      'fr-badge fr-badge--info fr-badge--sm'
    end
  end
end

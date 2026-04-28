# frozen_string_literal: true

class MarketAttributeResponse::TextInput::AutoFormComponent < ViewComponent::Base
  attr_reader :market_attribute_response, :form

  delegate :market_attribute, to: :market_attribute_response

  def initialize(market_attribute_response:, form:)
    @market_attribute_response = market_attribute_response
    @form = form
  end

  def field_label
    market_attribute.resolved_candidate_name
  end

  def auto_filled_message
    I18n.t('candidate.market_applications.auto_filled_message')
  end

  def text_value
    market_attribute_response.value&.dig('text') || ''
  end
end

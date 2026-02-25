# frozen_string_literal: true

class MarketAttributeResponse::TextInput::ManualFormComponent < ViewComponent::Base
  attr_reader :market_attribute_response, :form

  delegate :market_attribute, to: :market_attribute_response

  def initialize(market_attribute_response:, form:)
    @market_attribute_response = market_attribute_response
    @form = form
  end

  delegate :auto?, to: :market_attribute_response

  delegate :manual_after_api_failure?, to: :market_attribute_response

  def field_label
    market_attribute.resolved_candidate_name
  end

  def field_description
    market_attribute.resolved_candidate_description
  end

  def text_value
    market_attribute_response.value&.dig('text') || ''
  end

  def input_group_css_class
    css = 'fr-input-group'
    css += ' fr-input-group--error' if errors?
    css
  end

  def input_css_class
    css = 'fr-input'
    css += ' fr-input--error' if errors?
    css
  end

  def errors?
    market_attribute_response.errors[:text].any?
  end

  def error_messages
    market_attribute_response.errors[:text]
  end
end

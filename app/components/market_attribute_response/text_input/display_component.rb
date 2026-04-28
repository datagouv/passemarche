# frozen_string_literal: true

class MarketAttributeResponse::TextInput::DisplayComponent < ViewComponent::Base
  attr_reader :market_attribute_response, :context

  delegate :market_attribute, to: :market_attribute_response

  def initialize(market_attribute_response:, context: :web)
    @market_attribute_response = market_attribute_response
    @context = context
  end

  delegate :auto?, to: :market_attribute_response

  def show_value?
    !auto? || context == :buyer
  end

  def field_label
    market_attribute.resolved_candidate_name
  end

  def text_value
    market_attribute_response.value&.dig('text') || ''
  end

  def display_value
    text_value.presence || 'Non renseigné'
  end
end

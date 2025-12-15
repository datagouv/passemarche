# frozen_string_literal: true

class MarketAttributeResponse::Fields::TextareaFieldComponent < ViewComponent::Base
  attr_reader :form, :attribute_response, :rows, :readonly

  def initialize(form:, attribute_response:, rows: 6, readonly: false)
    @form = form
    @attribute_response = attribute_response
    @rows = rows
    @readonly = readonly
  end

  def text_value
    attribute_response.value&.dig('text') || ''
  end

  def errors?
    attribute_response.errors[:text].any?
  end

  def error_message
    attribute_response.errors[:text].first
  end

  def input_group_css_class
    css = 'fr-input-group fr-mb-2w'
    css += ' fr-input-group--error' if errors?
    css
  end

  def input_css_class
    'fr-input'
  end
end

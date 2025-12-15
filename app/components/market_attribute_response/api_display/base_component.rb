# frozen_string_literal: true

class MarketAttributeResponse::ApiDisplay::BaseComponent < ViewComponent::Base
  attr_reader :market_attribute_response, :context

  delegate :market_attribute, to: :market_attribute_response
  delegate :value, to: :market_attribute_response

  def initialize(market_attribute_response:, context: :web)
    @market_attribute_response = market_attribute_response
    @context = context
  end

  def buyer_context?
    context == :buyer
  end

  def show_details?
    buyer_context? || context == :web
  end

  def yes_no(boolean_value)
    boolean_value ? t('form_fields.candidate.shared.yes') : t('form_fields.candidate.shared.no')
  end

  def format_date(date_string)
    return date_string if date_string.blank?

    Date.parse(date_string).strftime('%d/%m/%Y')
  rescue ArgumentError, TypeError
    date_string
  end
end

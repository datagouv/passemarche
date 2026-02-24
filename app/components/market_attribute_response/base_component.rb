# frozen_string_literal: true

class MarketAttributeResponse::BaseComponent < ViewComponent::Base
  attr_reader :market_attribute_response, :form, :context

  delegate :market_attribute, to: :market_attribute_response
  delegate :auto?, :manual_after_api_failure?, to: :market_attribute_response

  def initialize(market_attribute_response:, form: nil, context: :web)
    @market_attribute_response = market_attribute_response
    @form = form
    @context = context
  end

  def form_mode?
    form.present?
  end

  def display_mode?
    !form_mode?
  end

  def manual?
    market_attribute_response.manual? || market_attribute_response.manual_after_api_failure?
  end

  def show_value?
    !auto? || context == :buyer
  end

  def field_label
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.name",
      default: market_attribute.key.humanize
    )
  end

  def field_description
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.description",
      default: nil
    )
  end

  def auto_filled_message
    I18n.t('candidate.market_applications.auto_filled_message')
  end

  def source_badge_component
    SourceBadgeComponent.new(market_attribute_response:, context:)
  end
end

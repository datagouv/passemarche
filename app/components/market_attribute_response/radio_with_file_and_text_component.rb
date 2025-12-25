# frozen_string_literal: true

class MarketAttributeResponse::RadioWithFileAndTextComponent < MarketAttributeResponse::BaseComponent
  delegate :documents, to: :market_attribute_response
  delegate :attached?, to: :documents, prefix: :documents
  delegate :radio_choice, :radio_yes?, :radio_no?, :text, to: :market_attribute_response

  def text?
    text.present?
  end

  def formatted_text
    return '' if text.blank?

    helpers.simple_format(text, class: 'fr-text--sm')
  end

  def radio_yes_label
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.radio_yes",
      default: 'Oui'
    )
  end

  def radio_no_label
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.radio_no",
      default: 'Non'
    )
  end

  def text_field_label
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.text_label",
      default: 'Décrivez votre situation'
    )
  end

  def text_field_hint
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.text_hint",
      default: nil
    )
  end

  def no_info_message
    'Aucune information complémentaire fournie'
  end

  def conditional_content_hidden?
    radio_no?
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_attribute_response.market_application)
  end

  def errors?
    market_attribute_response.errors[:value].any? ||
      market_attribute_response.errors[:text].any? ||
      market_attribute_response.errors[:documents].any? ||
      market_attribute_response.errors[:radio_choice].any?
  end

  def text_errors?
    market_attribute_response.errors[:text].any?
  end

  def text_error_messages
    market_attribute_response.errors[:text]
  end

  def value_error_messages
    market_attribute_response.errors[:value]
  end

  def text_field_id
    "text-#{market_attribute_response.id}"
  end

  def text_aria_describedby
    "#{text_field_id}-messages"
  end
end

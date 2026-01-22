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

  def display_label
    I18n.t(
      "form_fields.candidate.fields.#{market_attribute.key}.display_label",
      default: nil
    )
  end

  def display_value
    return I18n.t('form_fields.candidate.shared.not_provided', default: 'Non renseigné') if radio_choice.nil?

    radio_yes? ? I18n.t('form_fields.candidate.shared.yes') : I18n.t('form_fields.candidate.shared.no')
  end

  def display_value?
    display_label.present?
  end

  def conditional_content_hidden?
    !radio_yes?
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

  def response_label
    I18n.t(
      'market_attribute_response.radio_with_file_and_text.response_label',
      default: 'Réponse :'
    )
  end

  def attached_documents_label
    I18n.t(
      'market_attribute_response.radio_with_file_and_text.attached_documents_label',
      default: 'Documents joints :'
    )
  end

  def text_aria_describedby
    "#{text_field_id}-messages"
  end

  def motifs_exclusion_category?
    market_attribute.category_key == 'motifs_exclusion'
  end

  def badge_class
    base_classes = 'fr-badge fr-badge--sm'

    return 'fr-badge fr-badge--warning fr-badge--sm' if radio_choice.nil?

    if motifs_exclusion_category?
      radio_yes? ? 'fr-badge fr-badge--error fr-badge--sm' : 'fr-badge fr-badge--success fr-badge--sm'
    else
      radio_yes? ? 'fr-badge fr-badge--success fr-badge--sm' : base_classes
    end
  end

  def badge_label
    return 'Non renseigné' if radio_choice.nil?

    radio_yes? ? 'Oui' : 'Non'
  end
end

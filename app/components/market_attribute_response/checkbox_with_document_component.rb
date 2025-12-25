# frozen_string_literal: true

class MarketAttributeResponse::CheckboxWithDocumentComponent < MarketAttributeResponse::BaseComponent
  delegate :documents, to: :market_attribute_response
  delegate :attached?, to: :documents, prefix: :documents
  delegate :checked?, to: :market_attribute_response

  def checkbox_label
    I18n.t(
      "candidate.market_applications.form_fields.#{market_attribute.key}.extra",
      default: market_attribute.key.humanize
    )
  end

  def unchecked_message
    'Non certifié'
  end

  def max_file_size
    MarketAttributeResponse::CheckboxWithDocument::MAX_FILE_SIZE
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_attribute_response.market_application)
  end

  def errors?
    market_attribute_response.errors[:checked].any? ||
      market_attribute_response.errors[:documents].any?
  end

  def checkbox_errors?
    market_attribute_response.errors[:checked].any?
  end

  def documents_errors?
    market_attribute_response.errors[:documents].any?
  end

  def checkbox_error_messages
    market_attribute_response.errors[:checked]
  end

  def documents_error_messages
    market_attribute_response.errors[:documents]
  end

  def input_id
    "upload-#{market_attribute_response.id}"
  end

  def aria_describedby
    "#{input_id}-messages"
  end
end
